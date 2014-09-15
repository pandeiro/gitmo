 ;;; gitmo.el --- HTTP service for cloning and viewing git repos  -*- lexical-binding: t; -*-

;; Copyright (C) 2014  Murphy McMahon

;; Author: Murphy McMahon <pandeiro@gmail.com>
;; URL: https://github.com/pandeiro/gitmo
;; Version: 0.1.0

;;; Commentary:

;; Uses `restroom` (see restroom.el for URL) for easier routing.
;; (This package requires that git be installed on the host machine.)

;;; Credits:
;;; Code:

(require 'f)
(require 'elnode)
(require 'json)

;; Filesystem locations
(defcustom gitmo-repos-dir (concat user-emacs-directory "gitmo")
  "Base directory from which gitmo will look for everything")
(defvar gitmo-raw-repos-dir (concat gitmo-repos-dir "/repositories")
  "Directories where repos are stored")
(defvar gitmo-htmlized-repos-dir (concat gitmo-repos-dir "/html")
  "Directory where HTMLized files are stored")

;; Util
(defun gitmo-api-response (data)
  (json-encode (list (cons "params" data))))

(defun gitmo-ensure-directories ()
  (dolist (d (list gitmo-repos-dir
                   gitmo-raw-repos-dir
                   gitmo-htmlized-repos-dir))
    (when (not (f-directory? d))
      (message (concat "gitmo: Directory " d " not found; creating..."))
      (f-mkdir d))))

(defun gitmo-github-url (user repo)
  (concat "git://github.com/" user "/" repo))

;; Assets
(defvar gitmo-index "
<!doctype html>
<html>
  <head>
    <meta charset=\"utf-8\">
    <title></title>
  </head>
  <body>
    <h1>Hello</h1>
  </body>
</html>
")

;; Handlers
(defun gitmo-main-handler (httpcon)
  (elnode-http-start httpcon 200 '("Content-Type" . "text/html"))
  (elnode-http-return httpcon gitmo-index))

(defconst gitmo-htmlized-repos-handler
  (elnode-webserver-handler-maker gitmo-htmlized-repos-dir))

(defun gitmo-new-repo-handler (httpcon)
  "TODO: if repo exists already, pull; otherwise clone"
  (let* ((user-name (elnode-http-param httpcon "user"))
         (repo-name (elnode-http-param httpcon "repo"))
         (raw-url   (elnode-http-param httpcon "url")))
    (let* ((default-directory gitmo-raw-repos-dir)
           (repo-url (if raw-url raw-url (gitmo-github-url user-name repo-name)))
           (buffer-name (concat "*gitmo: git clone " repo-url "*")))
      (async-shell-command (concat "git clone " repo-name) buffer-name))
    (elnode-http-start httpcon 201 '("Content-Type" . "application/json"))
    (elnode-http-return httpcon (json-encode '((ok . t))))))

(defconst gitmo-routes
  '(("^/$" . gitmo-main-handler)
    ("^/html$" . gitmo-htmlized-repos-handler)
    ("^/repo$" . gitmo-new-repo-handler)))

(defun gitmo-dispatcher (httpcon)
  (elnode-dispatcher httpcon gitmo-routes))

(defun gitmo-run ()
  (interactive)
  (gitmo-ensure-directories)
  (elnode-start 'gitmo-dispatcher :port 7000 :host "localhost"))

;; Usage:

;(require 'gitmo)

;(gitmo-run)


