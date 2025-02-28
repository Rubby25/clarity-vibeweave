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

;; Data Variables
(define-data-var max-songs-per-playlist uint u100)

(define-map playlists
    { playlist-id: uint }
    {
        creator: principal,
        name: (string-ascii 50),
        description: (string-ascii 200),
        active: bool,
        song-count: uint,
        created-at: uint,
        category: (string-ascii 20)
    }
)

(define-map playlist-moderators
    { playlist-id: uint, moderator: principal }
    { can-moderate: bool }
)

(define-map songs
    { playlist-id: uint, song-id: uint }
    {
        submitter: principal,
        title: (string-ascii 100),
        artist: (string-ascii 100),
        duration: uint,
        votes: uint,
        played: bool,
        added-at: uint
    }
)

(define-map user-votes
    { playlist-id: uint, song-id: uint, user: principal }
    { voted: bool }
)

(define-data-var last-playlist-id uint u0)
(define-data-var last-song-id uint u0)

;; Private Functions
(define-private (is-moderator (playlist-id uint) (user principal))
    (default-to
        false
        (get can-moderate
            (map-get? playlist-moderators { playlist-id: playlist-id, moderator: user })
        )
    )
)

(define-private (is-valid-playlist (playlist-id uint))
    (match (map-get? playlists { playlist-id: playlist-id })
        playlist (get active playlist)
        false
    )
)

;; Public Functions
(define-public (create-playlist (name (string-ascii 50)) (description (string-ascii 200)) (category (string-ascii 20)))
    (let
        (
            (new-id (+ (var-get last-playlist-id) u1))
        )
        (try! (asserts! (is-eq tx-sender contract-owner) err-owner-only))
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

(define-public (toggle-playlist-status (playlist-id uint))
    (let ((playlist (unwrap! (map-get? playlists { playlist-id: playlist-id }) err-invalid-playlist)))
        (try! (asserts! (is-moderator playlist-id tx-sender) err-not-moderator))
        (map-set playlists
            { playlist-id: playlist-id }
            (merge playlist { active: (not (get active playlist)) })
        )
        (ok true)
    )
)

(define-public (add-song (playlist-id uint) (title (string-ascii 100)) (artist (string-ascii 100)) (duration uint))
    (let
        (
            (new-song-id (+ (var-get last-song-id) u1))
            (playlist (unwrap! (map-get? playlists { playlist-id: playlist-id }) err-invalid-playlist))
        )
        (try! (asserts! (is-valid-playlist playlist-id) err-playlist-inactive))
        (try! (asserts! (> (len title) u0) err-invalid-params))
        (try! (asserts! (< (get song-count playlist) (var-get max-songs-per-playlist)) err-capacity-reached))
        
        (map-set songs
            { playlist-id: playlist-id, song-id: new-song-id }
            {
                submitter: tx-sender,
                title: title,
                artist: artist,
                duration: duration,
                votes: u0,
                played: false,
                added-at: block-height
            }
        )
        (map-set playlists
            { playlist-id: playlist-id }
            (merge playlist { song-count: (+ (get song-count playlist) u1) })
        )
        (var-set last-song-id new-song-id)
        (ok new-song-id)
    )
)

;; [Previous functions remain unchanged...]
