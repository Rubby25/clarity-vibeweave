;; VibeWeave - Collaborative Playlist Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-moderator (err u101))
(define-constant err-invalid-playlist (err u102))
(define-constant err-already-voted (err u103))

;; Data Variables
(define-map playlists
    { playlist-id: uint }
    {
        creator: principal,
        name: (string-ascii 50),
        description: (string-ascii 200),
        active: bool,
        created-at: uint
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

;; Public Functions
(define-public (create-playlist (name (string-ascii 50)) (description (string-ascii 200)))
    (let
        (
            (new-id (+ (var-get last-playlist-id) u1))
        )
        (try! (asserts! (is-eq tx-sender contract-owner) err-owner-only))
        (map-set playlists
            { playlist-id: new-id }
            {
                creator: tx-sender,
                name: name,
                description: description,
                active: true,
                created-at: block-height
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

(define-public (add-song (playlist-id uint) (title (string-ascii 100)) (artist (string-ascii 100)))
    (let
        (
            (new-song-id (+ (var-get last-song-id) u1))
        )
        (asserts! (map-get? playlists { playlist-id: playlist-id }) err-invalid-playlist)
        (map-set songs
            { playlist-id: playlist-id, song-id: new-song-id }
            {
                submitter: tx-sender,
                title: title,
                artist: artist,
                votes: u0,
                played: false,
                added-at: block-height
            }
        )
        (var-set last-song-id new-song-id)
        (ok new-song-id)
    )
)

(define-public (vote-song (playlist-id uint) (song-id uint))
    (let
        (
            (vote-key { playlist-id: playlist-id, song-id: song-id, user: tx-sender })
        )
        (asserts! (map-get? playlists { playlist-id: playlist-id }) err-invalid-playlist)
        (asserts! (not (default-to false (get voted (map-get? user-votes vote-key)))) err-already-voted)
        
        (match (map-get? songs { playlist-id: playlist-id, song-id: song-id })
            song
            (begin
                (map-set songs
                    { playlist-id: playlist-id, song-id: song-id }
                    (merge song { votes: (+ (get votes song) u1) })
                )
                (map-set user-votes vote-key { voted: true })
                (ok true)
            )
            err-invalid-playlist
        )
    )
)

(define-public (add-moderator (playlist-id uint) (moderator principal))
    (begin
        (asserts! (is-moderator playlist-id tx-sender) err-not-moderator)
        (map-set playlist-moderators
            { playlist-id: playlist-id, moderator: moderator }
            { can-moderate: true }
        )
        (ok true)
    )
)

;; Read Only Functions
(define-read-only (get-playlist-info (playlist-id uint))
    (ok (map-get? playlists { playlist-id: playlist-id }))
)

(define-read-only (get-song-info (playlist-id uint) (song-id uint))
    (ok (map-get? songs { playlist-id: playlist-id, song-id: song-id }))
)

(define-read-only (is-user-moderator (playlist-id uint) (user principal))
    (ok (is-moderator playlist-id user))
)