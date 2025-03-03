;; VibeWeave - Collaborative Playlist Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-moderator (err u101))
(define-constant err-invalid-playlist (err u102))
(define-constant err-already-voted (err u103))
(define-constant err-playlist-inactive (err u104))
(define-constant err-invalid-params (err u105))
(define-constant err-capacity-reached (err u106))
(define-constant err-duplicate-song (err u107))
(define-constant err-song-not-found (err u108))

;; Data Variables
(define-data-var max-songs-per-playlist uint u100)

;; [Previous map definitions remain unchanged...]

;; New Functions
(define-private (is-song-duplicate (playlist-id uint) (title (string-ascii 100)) (artist (string-ascii 100)))
    (default-to 
        false
        (fold check-song-duplicate
            (list true)
            (unwrap! (get-playlist-songs playlist-id) false)
        )
    )
)

(define-public (remove-song (playlist-id uint) (song-id uint))
    (let (
        (playlist (unwrap! (map-get? playlists { playlist-id: playlist-id }) err-invalid-playlist))
        (song (unwrap! (map-get? songs { playlist-id: playlist-id, song-id: song-id }) err-song-not-found))
    )
        (try! (asserts! (is-moderator playlist-id tx-sender) err-not-moderator))
        (map-delete songs { playlist-id: playlist-id, song-id: song-id })
        (map-set playlists
            { playlist-id: playlist-id }
            (merge playlist { song-count: (- (get song-count playlist) u1) })
        )
        (ok true)
    )
)

(define-public (transfer-playlist-ownership (playlist-id uint) (new-owner principal))
    (let ((playlist (unwrap! (map-get? playlists { playlist-id: playlist-id }) err-invalid-playlist)))
        (try! (asserts! (is-eq tx-sender (get creator playlist)) err-owner-only))
        (map-set playlists
            { playlist-id: playlist-id }
            (merge playlist { creator: new-owner })
        )
        (map-set playlist-moderators
            { playlist-id: playlist-id, moderator: new-owner }
            { can-moderate: true }
        )
        (ok true)
    )
)

;; Modified create-playlist function to allow any user to create playlists
(define-public (create-playlist (name (string-ascii 50)) (description (string-ascii 200)) (category (string-ascii 20)))
    (let
        (
            (new-id (+ (var-get last-playlist-id) u1))
        )
        (try! (asserts! (> (len name) u0) err-invalid-params))
        (map-set playlists
            { playlist-id: new-id }
            {
                creator: tx-sender,
                name: name,
                description: description,
                active: true,
                song-count: u0,
                created-at: block-height,
                category: category
            }
        )
        (var-set last-playlist-id new-id)
        (map-set playlist-moderators
            { playlist-id: new-id, moderator: tx-sender }
            { can-moderate: true }
        )
        (ok new-id)
    )
)

;; [Previous functions remain unchanged...]
