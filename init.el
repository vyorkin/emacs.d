(add-hook 'emacs-startup-hook
  (lambda ()
    (message
     "Emacs ready in %s with %d GC's."
     (format
      "%.2f seconds"
      (float-time (time-subtract after-init-time before-init-time)))
     gcs-done)))

;;; -*- lexical-binding: t -*-

(setq gc-cons-threshold most-positive-fixnum)

(setq load-prefer-newer noninteractive)

(defvar my/lat 55.84)
(defvar my/lon 37.34)
(defvar my/location "Moscow, RU")

(defun my/emacs-path (path)
  "Expands `path` with Emacs home directory."
  (expand-file-name path user-emacs-directory))

(defun my/tmp-path (path)
  "Expand `path` with Emacs temporary directory."
  (my/emacs-path (format "tmp/%s" path)))

(defun my/lisp-path (path)
  "Expand `path` with Emacs `/lisp` directory."
  (my/emacs-path (format "lisp/%s" path)))

(require 'package)

;; Try to uncomment this if you have TLS-related issues
;; (setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3")

(let* ((no-ssl (and (memq system-type '(windows-nt ms-dos))
                    (not (gnutls-available-p))))
    (proto (if no-ssl "http" "https")))
    (add-to-list 'package-archives (cons "melpa" (concat proto "://melpa.org/packages/")) t))

(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile (require 'use-package))

(setq
 use-package-always-ensure t
 use-package-verbose nil)

(if (require 'quelpa nil t)
  ;; Prevent quelpa from doing anyting that requires network connection.
  (setq
   quelpa-update-melpa-p nil    ; Don't update MELPA git repo
   quelpa-checkout-melpa-p nil  ; Don't clone MELPA git repo
   quelpa-upgrade-p nil         ; Don't try to update packages automatically
   quelpa-self-upgrade-p nil)   ; Don't upgrade quelpa automatically

(unless (package-installed-p 'quelpa)
  (with-temp-buffer
    (url-insert-file-contents "https://github.com/quelpa/quelpa/raw/master/quelpa.el")
    (eval-buffer)
    ;; Comment/uncomment line below to disable/enable quelpa auto-upgrade.
    (quelpa-self-upgrade))))

(quelpa
 '(quelpa-use-package
   :fetcher github
   :repo "quelpa/quelpa-use-package"))
(require 'quelpa-use-package)

(quelpa-use-package-activate-advice)

(use-package use-package-custom-update
 :quelpa
 (use-package-custom-update
   :repo "a13/use-package-custom-update"
   :fetcher github
   :version original))

(use-package use-package-secrets
 :custom
 (use-package-secrets-directories '("~/.emacs.d/secrets"))
 :quelpa
 (use-package-secrets
   :repo "a13/use-package-secrets"
   :fetcher github
   :version original))

(use-package exec-path-from-shell
 :commands
 (exec-path-from-shell-copy-envs
  exec-path-from-shell-initialize)
 :init
 (setq exec-path-from-shell-check-startup-files nil)
 :config
 (exec-path-from-shell-copy-envs '("WAKATIME_API_KEY"))
 (when (memq window-system '(mac ns x))
   (exec-path-from-shell-initialize)))

(setq byte-compile-warnings '(not obsolete))

(eval-when-compile
  (setq use-package-expand-minimally byte-compile-current-file))

(setq ad-redefinition-action 'accept)

(setq create-lockfiles nil)

(setq
 make-backup-files nil        ; disable backup files
 auto-save-list-file-name nil ; disable .saves files
 auto-save-default nil        ; disable auto saving
 ring-bell-function 'ignore)  ; turn off alarms completely

(setq-default bidi-display-reordering nil)

(fset 'yes-or-no-p 'y-or-n-p)

(setq-default confirm-nonexistent-file-or-buffer t)

(setq
 recentf-auto-cleanup 'never
 recentf-max-menu-items 0
 recentf-max-saved-items 300
 recentf-filename-handlers '(file-truename abbreviate-file-name))

(recentf-mode 1)

(setq
 save-place-forget-unreadable-files t
 save-place-limit 400)

(save-place-mode 1)

(setq
 calendar-location-name my/location
 calendar-latitude my/lat
 calendar-longitude my/lon)

(require 'color)

(use-package files
  :ensure nil
  :preface
  (defun my/files/setup ()
    (add-hook 'before-save-hook 'delete-trailing-whitespace))
  :commands
  (generate-new-buffer
   executable-find
   file-name-base
   file-name-extension)
  :custom
  (require-final-newline t)
  :hook
  (prog-mode . my/files/setup))

(use-package autorevert
 :ensure nil
 :custom
 ;; Don't generate any messages whenever a buffer is reverted
 (auto-revert-verbose nil)
 ;; Operate only on file-visiting buffers
 (global-auto-revert-non-file-buffers t)
 :diminish auto-revert-mode)

(use-package uniquify
 :ensure nil
 :custom
 ;; use "foo/bar/qux"
 (uniquify-buffer-name-style 'forward))

(use-package savehist
  :ensure nil
  :custom
  (savehist-additional-variables
   '(kill-ring
     ;; search entries
     search-ring
     regexp-search-ring))
  ;; save every minute
  (savehist-autosave-interval 60)
  (savehist-save-minibuffer-history t)
  :init
  (savehist-mode 1))

(use-package frame
 :ensure nil
 :config
 (blink-cursor-mode 0)
 :bind
 ("C-z" . nil))

(use-package delsel
 :ensure nil
 :bind
 ("C-c C-g" . minibuffer-keyboard-quit))

(use-package simple
  :ensure nil
  :diminish
  ((visual-line-mode . " ↩")
   (auto-fill-function . " ↵"))
  :bind
  ;; remap ctrl-w/ctrl-h
  (("C-c h" . help-command)
   ("C-x C-k" . kill-region)
   ("C-h" . delete-backward-char)))

(use-package vc-hooks
  :ensure nil
  :config
  (setq
   vc-follow-symlinks t
   vc-make-backup-files nil))

(use-package prog-mode
 :ensure nil
 :commands
 (global-prettify-symbols-mode)
 :init
 (setq prettify-symbols-unprettify-at-point 'right-edge)
 :config
 ;; convert certain words into symbols, e.g. lambda becomes λ.
 (global-prettify-symbols-mode t))

(use-package ibuffer
 :ensure nil
 :bind
 ;; Set all global list-buffers bindings to use ibuffer
 ([remap list-buffers] . ibuffer))

(use-package mule
 :commands
 (set-terminal-coding-system)
 :ensure nil
 :config
 (prefer-coding-system 'utf-8)
 (set-terminal-coding-system 'utf-8)
 (set-language-environment "UTF-8"))

(use-package etags
 :ensure nil
 :custom
 ;; Don't add a new tags to the current list.
 ;; Always start a new list.
 (tags-add-tables nil))

(use-package man
 :ensure nil
 :custom-face
 (Man-overstrike ((t (:inherit font-lock-type-face :bold t))))
 (Man-underline ((t (:inherit font-lock-keyword-face :underline t)))))

(use-package calendar
 :ensure nil
 :custom
 (calendar-week-start-day 1))

(use-package face-remap
 :commands
 (buffer-face-mode-face
  face-remap-add-relative
  buffer-face-mode)
 :ensure nil
 :diminish buffer-face-mode)

(use-package cc-mode
 :ensure nil
 :config
 ;; (add-to-list 'auto-mode-alist '("\\.m\\'" . objc-mode))
 (add-to-list 'auto-mode-alist '("\\.mm\\'" . objc-mode)))

(use-package compile
  :custom
  (compilation-always-kill t)
  (compilation-ask-about-save nil)
  (compilation-scroll-output t)
  :init
  (make-variable-buffer-local 'compile-command)
  (put 'compile-command 'safe-local-variable 'stringp))

(advice-add
 'sh-set-shell :around
 (lambda (orig-fun &rest args)
   (let ((inhibit-message t))
     (apply orig-fun args))))

(use-package async
  :demand t
  :config
  (autoload 'dired-async-mode "dired-async.el" nil t)
  (dired-async-mode 1)
  (async-bytecomp-package-mode 1))

(use-package alert)

(setq
 inhibit-startup-screen t ; Don't show splash screen
 use-dialog-box nil       ; Disable dialog boxes
 use-file-dialog nil)     ; Disable file dialog

(when (memq window-system '(mac ns))
  (add-to-list 'default-frame-alist '(ns-appearance . dark)) ;; {light, dark}
  (add-to-list 'default-frame-alist '(ns-transparent-titlebar . t)))

(setq
 auto-window-vscroll nil
 hscroll-margin 5
 hscroll-step 5
 scroll-conservatively 101
 scroll-margin 0
 scroll-preserve-screen-position t)

(setq-default
 scroll-down-aggressively 0.01
 scroll-up-aggressively 0.01)

(tool-bar-mode -1)
(scroll-bar-mode -1)
(when (fboundp 'horizontal-scroll-bar-mode)
  (horizontal-scroll-bar-mode -1))

(if (eq system-type 'darwin)
    (add-hook 'after-make-frame-functions
              (lambda (frame)
                (set-frame-parameter frame 'menu-bar-lines
                                     (if (display-graphic-p frame) 1 0))))
  (when (fboundp 'menu-bar-mode)
    (menu-bar-mode -1)))

(setq-default blink-matching-paren nil)

(setq-default cursor-in-non-selected-windows nil)

(setq-default
 cursor-type 'bar
 x-stretch-cursor t)

(setq-default frame-title-format "%b (%f)")

(setq-default frame-inhibit-implied-resize t)

(fringe-mode '(12 . 12))

(setq-default
 fringes-outside-margins t
 left-fringe-width 8
 right-fringe-width 8
 indicate-buffer-boundaries 'left)

(setq-default
 fringe-indicator-alist
 (delq (assq 'continuation fringe-indicator-alist) fringe-indicator-alist))

(when (boundp 'window-divider-mode)
  (setq window-divider-default-places t
        window-divider-default-bottom-width 0
        window-divider-default-right-width 0)
  (window-divider-mode +1))

(add-hook
 'term-mode-hook
 (lambda () (setq line-spacing 0)))

(setq show-paren-style 'parenthesis)
(show-paren-mode 1)

(setq delete-selection-mode t)

(setq-default
 left-margin-width 1
 right-margin-width 1)

(setq mode-line-default-help-echo nil)

(setq
 mode-line-position
 '((line-number-mode ("%l" (column-number-mode ":%c")))))

(use-package time
  :ensure nil
  :custom
  (display-time-default-load-average nil)
  (display-time-24hr-format t)
  :config
  (display-time-mode t))

(use-package faces
  :ensure nil
  :custom
  (face-font-family-alternatives
   '(("JetBrains Mono" "Hack" "Consolas" "Monaco" "Monospace")))
  :init
  (set-face-attribute
   'default nil
   :family (caar face-font-family-alternatives)
   :weight 'regular
   :height 120
   :width 'semi-condensed)
  (set-fontset-font
   "fontset-default"
   'cyrillic
   (font-spec :registry "iso10646-1" :script 'cyrillic)))

(setq
 font-lock-maximum-decoration
 '((c-mode . 2) (c++-mode . 1) (t . 1)))

(setq font-lock-support-mode 'jit-lock-mode)
(setq
 jit-lock-stealth-time 16
 jit-lock-defer-contextually t
 jit-lock-stealth-nice 0.5)

(setq custom-file (my/emacs-path "custom.el"))
(load custom-file 'noerror)

(setq
 ;; sentences should end in one space
 sentence-end-double-space nil
 ;; empty scratch buffer
 initial-scratch-message nil
 ;; show keystrokes right away,
 ;; don't show the message in the scratch buffer
 echo-keystrokes 0.1
 ;; disable native fullscreen support
 ns-use-native-fullscreen nil)

(setq
 max-mini-window-height 0.3
 resize-mini-windows 'grow-only)

(setq
 ;; allow minibuffer commands in the minibuffer
 enable-recursive-minibuffers t
 ;; keep the point out of the minibuffer
 minibuffer-prompt-properties
 '(read-only t point-entered minibuffer-avoid-prompt face minibuffer-prompt))

(add-hook 'after-save-hook #'executable-make-buffer-file-executable-if-script-p)

(setq-default
 indent-tabs-mode nil
 tab-width 2)

(setq
  line-number-mode t
  column-number-mode t)

(setq-default truncate-lines t)

(setq-default fill-column 64)

(add-hook 'text-mode-hook 'turn-on-auto-fill)

(use-package base16-theme
  :config
  ;; (load-theme 'base16-default-dark t)
  (load-theme 'base16-grayscale-dark t)
  ;; (load-theme 'base16-grayscale-light t)
  ;; (load-theme 'base16-gruvbox-light-hard t)
  ;; (load-theme 'base16-material-palenight t) ;; ****
  ;; (load-theme 'base16-rebecca t)
  ;; (load-theme 'base16-pop t)
  ;; (load-theme 'base16-tomorrow-night t)
  ;; (load-theme 'base16-twilight t)
  ;; (load-theme 'base16-irblack t)

)

(use-package kurecolor)

(defvar my/leader "SPC")
(defvar my/leader+ "C-SPC")

(use-package general
 :config

(general-define-key
 "C-h" 'windmove-left
 "C-l" 'windmove-right
 "C-k" 'windmove-up
 "C-j" 'windmove-down
 "C-c C-k" 'kill-region)

(when (eq system-type 'darwin)
  (general-define-key
   "s-<backspace>" 'kill-whole-line
   "M-S-<backspace>" 'kill-word
   ;; Use Super for movement and selection just like in macOS
   "s-<right>" (kbd "C-e")
   "S-s-<right>" (kbd "C-S-e")
   "s-<left>" (kbd "M-m")
   "S-s-<left>" (kbd "M-S-m")
   "s-<up>" 'beginning-of-buffer
   "s-<down>" 'end-of-buffer
   ;; Basic things you should expect from macOS
   "s-a" 'mark-whole-buffer       ; select all
   "s-s" 'save-buffer             ; save
   "s-S" 'write-file              ; save as
   "s-q" 'save-buffers-kill-emacs ; quit
   ;; Go to other windows easily with one keystroke
   ;; s-something instead of C-x something
   "s-o" (kbd "C-x o")
   "s-w" (kbd "C-x 0") ; just like close tab in a web browser
   "s-W" (kbd "C-x 1") ; close others with shift
   ;; Move between windows with Control-Command-Arrow and
   ;; with Cmd just like in iTerm
   "s-[" 'windmove-left   ; Cmd+[ go to left window
   "s-]" 'windmove-right  ; Cmd+] go to right window
   "s-{" 'windmove-up     ; Cmd+Shift+[ go to upper window
   "<s-}>" 'windmove-down ; Ctrl+Shift+[ go to down window
   ;; Prev/next buffer
   "s-<" 'previous-buffer
   "s->" 'next-buffer))

(general-evil-setup t)

(nmap
 ";" 'evil-ex
 ":" 'evil-repeat-find-char)

(nmap 'messages-buffer-mode-map
  "0" 'evil-digit-argument-or-evil-beginning-of-line)

(nmap 'process-menu-mode-map
  "M-d" 'process-menu-delete-process
  "q" 'kill-buffer-and-window)

(nmap
  :prefix my/leader

  "v" 'split-window-horizontally
  "s" 'split-window-vertically

  "@" 'xref-find-definitions
  "#" 'xref-find-references

  "E e" 'eval-expression
  "E l" 'eval-last-sexp

  "h k" 'describe-key-briefly
  "h K" 'describe-key
  "h M" 'describe-mode
  "h m" 'info-display-manual)

  "P s" 'profiler-start
  "P S" 'profiler-stop
  "P r" 'profiler-report

  "p" 'list-processes
  "\\" 'widen

)

(use-package gcmh
  :config
  (gcmh-mode 1))

(use-package server
  :ensure nil
  :commands server-running-p
  :preface
  (defun my/server-ensure-running (frame)
    "Ensure server is running when launching FRAME."
    (with-selected-frame frame
      (unless (server-running-p)
        (server-start))))
  :init
  (add-hook 'after-make-frame-functions #'my/server-ensure-running))

(setq
  delete-by-moving-to-trash t
  trash-directory (my/emacs-path "trash"))

(cl-pushnew
 '("^*Async Shell Command*" . (display-buffer-no-window))
 display-buffer-alist
 :test #'equal)

(use-package visual-fill-column
  :custom
  (visual-fill-column-center-text t))

(use-package copy-as-format
 :after general
 :config
 (vmap
   :prefix "C-c f"
   "f" 'copy-as-format
   "a" 'copy-as-format-asciidoc
   "b" 'copy-as-format-bitbucket
   "d" 'copy-as-format-disqus
   "g" 'copy-as-format-github
   "l" 'copy-as-format-gitlab
   "h" 'copy-as-format-html
   "j" 'copy-as-format-jira
   "m" 'copy-as-format-markdown
   "w" 'copy-as-format-mediawiki
   "o" 'copy-as-format-org-mode
   "p" 'copy-as-format-pod
   "r" 'copy-as-format-rst
   "s" 'copy-as-format-slack))

(use-package posframe
  :custom
  (posframe-mouse-banish nil))

(use-package ws-butler
 :hook
 (prog-mode . ws-butler-mode)
 :diminish ws-butler-mode)

(use-package auto-read-only
 :config
 (auto-read-only-mode 1)
 ;; Automatically make the init.el read-only because it is a
 ;; generated file.
 (add-to-list 'auto-read-only-file-regexps "~/.emacs.d/init.el"))

(use-package frame-fns
 :demand t
 :quelpa (frame-fns :fetcher github :repo "emacsmirror/frame-fns"))
(use-package frame-cmds
 :demand t
 :quelpa (frame-cmds :fetcher github :repo "emacsmirror/frame-cmds"))

(use-package zoom-frm
 :after (frame-fns frame-cmds)
 :quelpa (zoom-frm :fetcher github :repo "emacsmirror/zoom-frm")
 :config
 (nmap
   "C-=" 'zoom-frm-in
   "C--" 'zoom-frm-out
   "<s-triple-wheel-up>" 'zoom-frm-in
   "<s-triple-wheel-down>" 'zoom-frm-out))

(use-package zoom
 :custom
 (zoom-size '(0.8 . 0.8))
 (zoom-ignored-major-modes '(dired-mode pomidor-mode))
 (zoom-ignored-buffer-name-regexps '("^*calc"))
 (zoom-ignore-predicates '((lambda () (> (count-lines (point-min) (point-max)) 20)))))

(use-package seethru
 :demand t
 :commands
 (seethru)
 :config
 (seethru 100)
 ;; C-c 8, C-c 9
 (seethru-recommended-keybinds))

(use-package goto-chg
 :after general
 :config
 (nmap
   :prefix my/leader
   "." 'goto-last-change
   "," 'goto-last-change-reverse)
 ;; Additional keybindings for macOS
 (when (eq system-type 'darwin)
   (nmap
     "s-." 'goto-last-change
     "s-," 'goto-last-change-reverse)))

(use-package fullframe
 :config
 (fullframe list-packages quit-window)
 (fullframe package-list-packages quit-window))

(use-package vimish-fold
 :after evil
 :commands
 (vimish-fold-global-mode)
 :init
 (setq
  vimish-fold-blank-fold-header "<...>"
  vimish-fold-indication-mode 'right-fringe)
 :config
 (vimish-fold-global-mode 1))

(use-package which-key
 :diminish which-key-mode
 :init
 (setq
  which-key-idle-delay 1.0
  which-key-sort-order 'which-key-prefix-then-key-order-reverse
  ;; Hack to make this work with Evil
  which-key-show-operator-state-maps t
  which-key-prefix-prefix ""
  which-key-side-window-max-width 0.5
  which-key-popup-type 'side-window
  which-key-side-window-location 'bottom)
 :config
 (which-key-mode)
 (with-eval-after-load 'evil-collection
   (add-to-list 'evil-collection-mode-list 'while-key)))

(use-package free-keys)

(use-package vlf)

(use-package sudo-edit)

(use-package try)

(use-package restart-emacs
 :after general
 :demand t
 :config
 (nmap
   :prefix my/leader
   "Z" 'restart-emacs))

(defun my/customize-appearance ()
  (interactive)
  ;; set the background or vertical border to the main area background color
  (set-face-background 'vertical-border (face-background 'default))
  ;; set the foreground and background of the vertical-border face to
  ;; the same value so there is no line up the middle
  (set-face-foreground 'vertical-border (face-background 'vertical-border))
  ;; set the fringe colors to whatever is the background color
  (set-face-attribute
   'fringe nil
   :foreground (face-foreground 'default)
   :background (face-background 'default))

  ;; Comment/uncomment the lines below to
  ;; set the highlight color for selected text:

  ;; (set-face-attribute 'region nil :foreground "#fff")
  ;; (set-face-attribute 'region nil :background "#282828")

  ;; Comment/uncomment the line below to
  ;; set the highlight color and foreground color for matching search results:

  ;; (set-face-attribute 'lazy-highlight nil :foreground "black" :background "#ffd700")
  )

(if (display-graphic-p)
    (my/customize-appearance)
  (add-hook
   'after-make-frame-functions
   (lambda (frame)
     (when (display-graphic-p frame)
       (with-selected-frame frame
         (my/customize-appearance))))))

(use-package rainbow-delimiters
 :commands
 (rainbow-delimiters-unmatched-face)
 :config
 ;; Pastels
 (set-face-attribute 'rainbow-delimiters-depth-1-face nil :foreground "#78c5d6")
 (set-face-attribute 'rainbow-delimiters-depth-2-face nil :foreground "#bf62a6")
 (set-face-attribute 'rainbow-delimiters-depth-3-face nil :foreground "#459ba8")
 (set-face-attribute 'rainbow-delimiters-depth-4-face nil :foreground "#e868a2")
 (set-face-attribute 'rainbow-delimiters-depth-5-face nil :foreground "#79c267")
 (set-face-attribute 'rainbow-delimiters-depth-6-face nil :foreground "#f28c33")
 (set-face-attribute 'rainbow-delimiters-depth-7-face nil :foreground "#c5d647")
 (set-face-attribute 'rainbow-delimiters-depth-8-face nil :foreground "#f5d63d")
 (set-face-attribute 'rainbow-delimiters-depth-9-face nil :foreground "#78c5d6")
 ;; Make unmatched parens stand out more
 (set-face-attribute
  'rainbow-delimiters-unmatched-face nil
   :foreground 'unspecified
   :inherit 'show-paren-mismatch
   :strike-through t)
 (set-face-foreground 'rainbow-delimiters-unmatched-face "magenta")
 :hook
 (prog-mode . rainbow-delimiters-mode)
 :diminish rainbow-delimiters-mode)

(use-package rainbow-identifiers
 :hook
 (prog-mode . rainbow-identifiers-mode)
 :diminish rainbow-identifiers-mode)

(use-package idle-highlight-mode
 :custom
 (idle-highlight-idle-time 0.5)
 :hook
 (prog-mode . idle-highlight-mode)
 :config
 (nmap
   :prefix my/leader
   "t H" 'idle-highlight-mode))

(use-package hl-line
  :custom
  ;; Only highlight in selected window
  (hl-line-sticky-flag nil)
  (global-hl-line-sticky-flag nil)
  :config
  (set-face-background 'hl-line "#151515")
  (global-hl-line-mode)
  (nmap
    :prefix my/leader
    "t l" 'global-hl-line-mode))

(use-package vline
  :quelpa
  (vline :fetcher github :repo "emacsmirror/vline"))

(use-package col-highlight
  :after (vline)
  :quelpa
  (col-highlight :fetcher github :repo "emacsmirror/col-highlight")
  ;; :hook
  ;; (prog-mode . column-highlight-mode)
  :config
  (set-face-background 'col-highlight "#151515")
  (nmap
    :prefix my/leader
    "t c" 'column-highlight-mode))

(use-package column-marker
  :quelpa
  (column-marker :fetcher github :repo "emacsmirror/column-marker"))

(use-package hl-todo
 :config
 (global-hl-todo-mode))

(use-package highlight-indentation
 :after general
 ;; :hook
 ;; (yaml-mode . highlight-indentation-mode)
 ;; (haskell-mode . highlight-indentation-mode)
 ;; (prog-mode . highlight-indentation-current-column-mode)
 :config
 ;; theme: zerodark
 ;; (set-face-background 'highlight-indentation-face "#24282f")
 ;; (set-face-background 'highlight-indentation-current-column-face "#22252c")
 ;; theme: grayscale dark
 (set-face-background 'highlight-indentation-face "#151515")
 (set-face-background 'highlight-indentation-current-column-face "#121212")
 (nmap
   :prefix my/leader
   "t i" 'highlight-indentation-mode
   "t I" 'highlight-indentation-current-column-mode)
 :diminish
 (highlight-indentation-mode
  highlight-indentation-current-column-mode))

(use-package all-the-icons
 :config
 (setq
   all-the-icons-mode-icon-alist
   `(,@all-the-icons-mode-icon-alist
     (package-menu-mode all-the-icons-octicon "package" :v-adjust 0.0)
     (jabber-chat-mode all-the-icons-material "chat" :v-adjust 0.0)
     (jabber-roster-mode all-the-icons-material "contacts" :v-adjust 0.0)
     (telega-chat-mode all-the-icons-fileicon "telegram" :v-adjust 0.0
                       :face all-the-icons-blue-alt)
     (telega-root-mode all-the-icons-material "contacts" :v-adjust 0.0))))

(use-package minions
 :config
 (setq minions-mode-line-lighter "[+]")
 (minions-mode 1))

(use-package moody
 :config
 (moody-replace-mode-line-buffer-identification)
 (moody-replace-vc-mode)
 (setq-default
  x-underline-at-descent-line t
  column-number-mode t))

(use-package hide-mode-line
 :config
 (add-hook 'completion-list-mode-hook #'hide-mode-line-mode)
 (nmap
   :prefix my/leader
   "t m" 'global-hide-mode-line-mode))

(use-package beacon
 :after (general)
 :demand t
 :commands (beacon-mode)
 :custom
 (beacon-size 12)
 (beacon-blink-delay 0.0)
 (beacon-blink-duration 0.5)
 (beacon-color "#ffd700")
 (beacon-blink-when-window-scrolls nil)
 (beacon-dont-blink-commands nil)
 :config
 (nmap
   :prefix my/leader
   "t b" 'beacon-mode)
 :diminish beacon-mode)

  (use-package evil
   :preface
   (defvar my/evil/esc-hook '(t)
     "A hook run after ESC is pressed in normal mode
     (invoked by `evil-force-normal-state').
     If a hook returns non-nil, all hooks after it are ignored.")
   (defun my/evil/attach-esc-hook ()
     "Run all escape hooks, if any returns non-nil, then stop there"
     (run-hook-with-args-until-success 'my/evil/esc-hook))
   :init
   (setq
    ;; Undo system Evil should use. If equal to ‘undo-tree’ or
    ;; ‘undo-fu’, those packages must be installed. If equal to
    ;; ‘undo-tree’, ‘undo-tree-mode’ must also be activated. If
    ;; equal to ‘undo-redo’, Evil uses commands natively available
    ;; in Emacs 28
    evil-undo-system 'undo-redo
    ;; evil-collection assumes evil-want-keybinding is set to nil
    ;; and evil-want-integration is set to t before loading evil
    ;; and evil-collection
    evil-want-keybinding nil
    evil-want-integration t
    ;; Restore missing C-u in evil so it scrolls up (like in Vim).
    ;; Otherwise C-u applies a prefix argument.
    evil-want-C-u-scroll t
    ;; C-w deletes a word in Insert state.
    evil-want-C-w-delete t
    ;; All changes made during insert state, including a possible
    ;; delete after a change operation, are collected in a single
    ;; undo step
    evil-want-fine-undo "no"
    ;; Inclusive visual character selection which ends at the
    ;; beginning or end of a line is turned into an exclusive
    ;; selection. Thus if the selected (inclusive) range ends at
    ;; the beginning of a line it is changed to not include the
    ;; first character of that line, and if the selected range
    ;; ends at the end of a line it is changed to not include the
    ;; newline character of that line
    evil-want-visual-char-semi-exclusive t
    ;; ‘Y’ yanks to the end of the line
    evil-want-Y-yank-to-eol t
    ;; Meaning which characters in a pattern are magic.
    ;; The meaning of those values is the same as in Vim
    evil-magic t
    ;; If non-nil abbrevs will be expanded when leaving insert
    ;; state like in Vim, if ‘abbrev-mode’ is on
    evil-want-abbrev-expand-on-insert-exit nil
    ;; Signal the current state in the echo area
    evil-echo-state t
    ;; The = operator converts between leading tabs and spaces.
    ;; Whether tabs are converted to spaces or vice versa depends
    ;; on the value of ‘indent-tabs-mode’
    evil-indent-convert-tabs t
    ;; Vim-style backslash codes are supported in search patterns
    evil-ex-search-vim-style-regexp t
    ;; Substitute patterns are global by default
    evil-ex-substitute-global t
    ;; Column range for ex commands
    evil-ex-visual-char-range t
    ;; Use evil interactive search module instead of isearch
    evil-search-module 'evil-search
    ;; If nil then * and # search for words otherwise for symbols
    evil-symbol-word-search t
    ;; Don't use emacs mode for ibuffer
    ;; evil-emacs-state-modes (delq 'ibuffer-mode evil-emacs-state-modes)
    ;; Cursors
    evil-default-cursor (face-background 'cursor nil t)
    evil-normal-state-cursor 'box
    evil-emacs-state-cursor `(,(face-foreground 'warning) box)
    evil-insert-state-cursor 'bar
    evil-visual-state-cursor 'box)
   :config
   ;; Enable evil-mode globally,
   ;; good for ex-vimmers like me
   (evil-mode t)
   ;; Special
   (evil-make-overriding-map special-mode-map 'normal)
   ;; Compilation
   (evil-set-initial-state 'compilation-mode 'normal)
   ;; Occur
   (evil-make-overriding-map occur-mode-map 'normal)
   (evil-set-initial-state 'occur-mode 'normal)
   (advice-add 'evil-force-normal-state :after 'my/evil/attach-esc-hook)
   ;; Unbind  evil-paste-pop and evil-paste-pop-next
   ;; which breaks evil-mc
   (with-eval-after-load 'evil-maps
     (define-key evil-normal-state-map (kbd "C-n") nil)
     (define-key evil-normal-state-map (kbd "C-p") nil)))

  (use-package evil-collection
    :init
    (setq
     ;; If you don't need everything - uncomment and add everything you want
     ;; evil-collection-mode-list '()

     ;; Don't enable vim key bindings in minibuffer
     ;; its a default setting, just want it to be explicitly stated here
     evil-collection-setup-minibuffer nil)
    :config
    (evil-collection-init)
    (nmap
      "C-M-l" 'evil-window-increase-width
      "C-M-h" 'evil-window-decrease-width
      "C-M-k" 'evil-window-increase-height
      "C-M-j" 'evil-window-decrease-height))

  (use-package evil-mc
   :after (general evil)
   :demand t
   :commands
   ;; Enable evil-mc mode for all buffers
   (global-evil-mc-mode)
   :preface
   (defun my/evil-mc/esc ()
     "Clear evil-mc cursors and restore state."
     (when (evil-mc-has-cursors-p)
       (evil-mc-undo-all-cursors)
       (evil-mc-resume-cursors)
       t))
   :config
   (global-evil-mc-mode 1)
   (add-hook 'my/evil/esc-hook 'my/evil-mc/esc)
   (mmap
     "C-n" 'evil-mc-make-and-goto-next-match)
   (when (eq system-type 'darwin)
     ;; Unbind isearch commands
     (unbind-key "s-d")
     (unbind-key "s-g")
     (mmap
       "s-d" 'evil-mc-make-and-goto-next-match
       "s-D" 'evil-mc-make-all-cursors))
   :diminish evil-mc-mode)

(use-package evil-matchit
 :after evil
 :demand t
 :commands
 (evilmi-jump-items
  evilmi-text-object
  global-evil-matchit-mode)
 :config
 (global-evil-matchit-mode 1))

(use-package evil-smartparens
  :after (smartparens)
  :config
  (add-hook 'smartparens-enabled-hook #'evil-smartparens-mode))

(use-package evil-string-inflection)

(use-package evil-surround
 :after evil
 :demand t
 :commands
 (global-evil-surround-mode
   evil-surround-edit
   evil-Surround-edit
   evil-surround-region)
 :config
 (global-evil-surround-mode 1))

(use-package evil-visualstar
 :after evil
 :commands
 (global-evil-visualstar-mode
   evil-visualstar/begin-search
   evil-visualstar/begin-search-forward
   evil-visualstar/begin-search-backward)
 :config
 (global-evil-visualstar-mode))

(use-package evil-vimish-fold
  :after (evil vimish-fold)
  :commands
  (evil-vimish-fold-mode)
  :config
  (evil-vimish-fold-mode 1)
  :hook
  (prog-mode . evil-vimish-fold-mode)
  (text-mode . evil-vimish-fold-mode)
  :diminish evil-vimish-fold-mode)

(use-package evil-commentary
 :after evil
 :demand t
 :commands
 (evil-commentary-mode
  evil-commentary-yank
  evil-commentary-line)
 :config (evil-commentary-mode)
 :diminish evil-commentary-mode)

(use-package evil-numbers
  :after (evil general)
  :demand t
  :config
  (nmap
    "C-c =" 'evil-numbers/inc-at-pt
    "C-c -" 'evil-numbers/dec-at-pt))

(use-package bookmark
  :after general
  :init
  (setq
   bookmark-version-control t
   bookmark-save-flag 1)
  :config
  ;; Uncomment if you prefer going straight to bookmarks on Emacs startup.
  ;; (bookmark-bmenu-list)
  ;; (switch-to-buffer "*Bookmark List*")
  (nmap
    :prefix my/leader
    "b" 'bookmark-set))

(defun my/company-mode/setup-faces ()
  (interactive)
  "Style company-mode nicely"
  (let* ((bg (face-attribute 'default :background))
         (bg-light (color-lighten-name bg 2))
         (bg-lighter (color-lighten-name bg 5))
         (bg-lightest (color-lighten-name bg 10))
         (ac (face-attribute 'match :foreground)))
    (custom-set-faces
     `(company-tooltip
       ((t (:inherit default :background ,bg-light))))
     `(company-scrollbar-bg ((t (:background ,bg-lightest))))
     `(company-scrollbar-fg ((t (:background ,bg-lighter))))
     `(company-tooltip-selection
       ((t (:inherit font-lock-function-name-face))))
     `(company-tooltip-common
       ((t (:inherit font-lock-constant-face))))
     `(company-preview-common
       ((t (:foreground ,ac :background ,bg-lightest)))))))

(use-package company
 :hook
 ;; Use company-mode in all buffers
 (after-init . global-company-mode)
 :custom
 (company-dabbrev-ignore-case nil)
 (company-dabbrev-code-ignore-case nil)
 (company-dabbrev-downcase nil)
 (company-idle-delay 0.2 "adjust this setting according to your typing speed")
 (company-minimum-prefix-length 1)
 (company-tooltip-align-annotations t)

 ;; Disable in org
 (company-global-modes '(not org-mode))
 :config
 (my/company-mode/setup-faces)
 (unbind-key "C-SPC")
 (imap
  "C-SPC" 'company-complete
  "M-SPC" 'company-complete)
 (general-define-key
  :keymaps 'company-active-map
  "C-j" 'company-select-next-or-abort
  "C-k" 'company-select-previous-or-abort
  "C-o" 'company-other-backend
  "C-f" 'company-abort
  "C-d" 'company-show-doc-buffer
  "C-w" 'backward-kill-word)
 :diminish company-mode)

(use-package company-quickhelp
 :after company
 :custom
 (company-quickhelp-delay 3)
 :config
 (general-define-key
  :keymaps 'company-active-map
  "C-c h" 'company-quickhelp-manual-begin))

(use-package flycheck
  :after (general)
  :demand t
  :commands
  (global-flycheck-mode)
  :init
  (setq-default
   flycheck-disabled-checkers
   '(emacs-lisp-checkdoc
     javascript-jshint
     haskell-stack-ghc
     haskell-ghc
     haskell-hlint))
  (setq
   flycheck-highlighting-mode 'lines
   flycheck-indication-mode 'left-fringe
   flycheck-mode-line-prefix "fly"
   flycheck-javascript-eslint-executable "eslint_d")
  :config
  (global-flycheck-mode 1)
  (nmap
    :prefix my/leader
    "t e" 'flycheck-mode
    "e e" 'flycheck-list-errors
    "e c" 'flycheck-clear
    "e i" 'flycheck-manual
    "e C" 'flycheck-compile
    "e n" 'flycheck-next-error
    "e p" 'flycheck-previous-error
    "e b" 'flycheck-buffer
    "e s" 'flycheck-select-checker
    "e v" 'flycheck-verify-setup
    "e V" 'flycheck-verify-checker)
  ;; Make the error list display like similar lists in contemporary IDEs
  ;; like VisualStudio, Eclipse, etc.
  (add-to-list
   'display-buffer-alist
   `(,(rx bos "*errors*" eos)
     ;; (display-buffer-reuse-window
     ;;  display-buffer-in-side-window)
     (side . bottom)
     (reusable-frames . visible)
     (window-height . 0.33)))
  (unbind-key "C-j" flycheck-error-list-mode-map)
  :diminish flycheck-mode)

(use-package flycheck-indicator
  :hook (flycheck-mode . flycheck-indicator-mode))

(use-package flycheck-posframe
  :after (flycheck)
  :config
  (flycheck-posframe-configure-pretty-defaults)
  (add-to-list
   'flycheck-posframe-inhibit-functions
   #'(lambda () (bound-and-true-p company-backend)))
  (setq flycheck-posframe-border-width 1)
  (set-face-attribute 'flycheck-posframe-background-face nil :inherit nil :background "#111")
  (set-face-attribute 'flycheck-posframe-error-face nil :inherit nil :foreground "red")
  (set-face-attribute 'flycheck-posframe-warning-face nil :foreground "skyblue")
  (set-face-attribute 'flycheck-posframe-info-face nil :foreground "white")
  :custom-face (flycheck-posframe-border-face ((t (:foreground "#353535"))))
  ;; :hook
  ;; (flycheck-mode . flycheck-posframe-mode)
)

(use-package flyspell
  :ensure nil
  :after (general ispell)
  :custom
  (flyspell-delay 1)
  (flyspell-always-use-popup t)
  :init
  (setq
   flyspell-use-meta-tab nil
   flyspell-mode-line-string ""
   flyspell-auto-correct-binding (kbd ""))
  :hook
  (;; Don’t check comments, thats too annoying
   ;; (prog-mode . flyspell-prog-mode)
   ;; Might be slow in large org-files
   (org-mode . (lambda () (flyspell-mode -1)))
   ((gfm-mode text-mode git-commit-mode) . flyspell-mode))
  :config
  (unbind-key "C-." flyspell-mode-map)
  (nmap
    :prefix my/leader
    "t f" 'flyspell-mode)
  (nmap
    "C-c i b" 'flyspell-buffer
    "C-c i f" 'flyspell-mode))

(use-package powerthesaurus
 :after general
 :config
 (nmap
   :prefix my/leader
   "L" 'powerthesaurus-lookup-word-at-point))

(use-package define-word
 :after general
 :config
 (nmap
   :prefix my/leader
   "D" 'define-word-at-point))

(use-package wordnut
  :if (executable-find "wordnet")
  :config
  (nmap
    :prefix my/leader
    "d" 'wordnut-lookup-current-word))

(defconst my/dired-html-files-extensions
  '("htm" "html" "xhtml" "phtml" "haml"
    "asp" "aspx" "xaml" "php" "jsp")
  "HTML files extensions")
(defconst my/dired-styles-files-extensions
  '("css" "sass" "scss" "less")
  "Styles files extensions")
(defconst my/dired-xml-files-extensions
  '("xml" "xsd" "xsl" "xslt" "wsdl")
  "XML files extensions")
(defconst my/dired-document-files-extensions
  '("doc" "docx" "ppt" "pptx" "xls" "xlsx"
    "csv" "rtf" "djvu" "epub""wps" "pdf" "texi" "tex"
    "odt" "ott" "odp" "otp" "ods" "ots"
    "odg" "otg")
  "Document files extensions")
(defconst my/dired-text-files-extensions
  '("txt" "md" "org" "ini" "conf" "rc" "vim" "vimrc" "exrc")
  "Text files extensions")
(defconst my/dired-sh-files-extensions
  '("sh" "bash" "zsh" "fish" "csh" "ksh"
    "awk" "ps1" "psm1" "psd1" "bat" "cmd")
  "Shell files extensions")
(defconst my/dired-source-files-extensions
  '("py" "c" "cc" "cpp" "cxx" "c++" "h" "hpp" "hxx" "h++"
    "java" "pl" "rb" "el" "pl" "pm" "l" "jl" "f90" "f95"
    "R" "php" "hs" "purs" "coffee" "ts" "js" "json" "m" "mm"
    "ml" "asm" "vb" "ex" "exs" "erl" "go" "clj" "cljs"
    "sql" "yml" "yaml" "toml" "rs" "idr" "cs" "mk" "make" "swift"
    "rake" "lua")
  "Source files extensions")
(defconst my/dired-compressed-files-extensions
  '("zip" "bz2" "tgz" "txz" "gz" "xz" "z" "Z"
    "war" "ear" "rar" "sar" "xpi" "apk" "tar" "7z"
    "gzip" "001" "ace" "lz"
    "lzma" "bzip2" "cab" "jar" "iso")
  "Compressed files extensions")
(defconst my/dired-image-files-extensions
  '("bmp" "jpg" "jpeg" "gif" "png" "tiff"
    "ico" "svg" "psd" "pcd" "raw" "exif"
    "BMP" "JPG" "PNG")
  "Image files extensions")
(defconst my/dired-audio-files-extensions
  '("mp3" "MP3" "ogg" "OGG" "flac" "FLAC" "wav" "WAV")
  "Dired Audio files extensions")
(defconst my/dired-video-files-extensions
  '("vob" "VOB" "mkv" "MKV" "mpe" "mpg" "MPG"
    "mp4" "MP4" "ts" "TS" "m2ts"
    "M2TS" "avi" "AVI" "mov" "MOV" "wmv"
    "asf" "m2v" "m4v" "mpeg" "MPEG" "tp")
  "Dired Video files extensions")
(defconst my/dired-misc-files-extensions
  '("DS_Store" "projectile" "cache" "elc" "dat" "meta")
  "Misc files extensions")

(use-package dired
 :after general
 :ensure nil
 :custom
 ;; Do not bind C-x C-j since it's used by jabber.el
 (dired-bind-jump nil)
 :init
 ;; Prevents dired from creating an annoying popup
 ;; when dired-find-alternate-file is called
 (setq
  ;; If there is a dired buffer displayed in the next window,
  ;; use its current directory
  dired-dwim-target t
  dired-omit-verbose nil
  ;; human readable filesize
  dired-listing-switches "-ahlv"
  ;; recursive copy & delete
  dired-recursive-deletes 'always
  dired-recursive-copies 'always)
 (setq
  dired-garbage-files-regexp
  "\\.\\(?:aux\\|out\\|bak\\|dvi\\|log\\|orig\\|rej\\|toc\\|class\\)\\'")
 ;; Enable omit mode
 ;; (setq-default dired-omit-mode t)
 ;; Hide autosave files
 ;; (setq-default dired-omit-files "^\\.?#")
 ;; Uncomment the line below if you want to hide dot files
 ;; (setq-default dired-omit-files (concat dired-omit-files "\\|^\\.[^\\.]"))
 (setq
  dired-omit-extensions
  '("CVS" "RCS" ".o" "~" ".bin" ".lbin" ".fasl" ".ufsl" ".a" ".ln" ".blg"
    ".bbl" ".elc" ".lof" ".glo" ".idx" ".aux" ".glob" ".vo"
    ".lot" ".fmt" ".tfm" ".class" ".DS_Store"
    ".fas" ".lib" ".x86f" ".sparcf" ".lo" ".la" ".toc" ".aux" ".cp" ".fn"
    ".ky" ".pg" ".tp" ".vr" ".cps" ".fns" ".kys" ".pgs" ".tps" ".vrs"
    ".idx" ".lof" ".lot" ".glo" ".blg" ".bbl" ".cp" ".cps" ".fn" ".fns"
    ".ky" ".kys" ".pg" ".pgs" ".tp" ".tps" ".vr" ".vrs" ".gv" ".gv.pdf"))
 ;; macOS ls command doesn't support "--dired" option
 (when (string= system-type "darwin")
   (setq dired-use-ls-dired nil))
 :config
 (put 'dired-find-alternate-file 'disabled nil)
 (nmap
   :prefix my/leader
   "j" 'dired-jump)
 (nmap 'dired-mode-map
   "gg" 'evil-goto-first-line
   "G" 'evil-goto-line
   "b" 'bookmark-set)
 :hook
 (dired-mode . dired-hide-details-mode)
 (dired-mode . hl-line-mode)
 :diminish dired-mode)

(use-package dired-hide-dotfiles
 :config
 (nmap 'dired-mode-map
   "." 'dired-hide-dotfiles-mode)
 :hook
 (dired-mode . dired-hide-dotfiles-mode))

(use-package diredfl
 :after dired
 :hook
 (dired-mode . diredfl-mode))

(use-package dired-rsync
 :config
 (nmap 'dired-mode-map
   "r" 'dired-rsync))

(use-package dired-launch
 :hook
 (dired-mode . dired-launch-mode)
 :init
 ;; Use xdg-open as the default launcher
 (setq dired-launch-default-launcher '("xdg-open"))
 :config
 (nmap 'dired-launch-mode-map
   "l" 'dired-launch-command))

(use-package dired+
 :after dired
 :quelpa
 (dired+ :fetcher github :repo "emacsmirror/dired-plus")
 :commands
 (dired-read-dir-and-switches)
 :init
 (setq
  diredp-hide-details-initially-flag nil
  diredp-hide-details-propagate-flag nil))

(use-package dash)
(use-package dired-hacks-utils
 :after dired
 :demand t)

(use-package dired-filter
 :after dired
 :hook
 (dired-mode . dired-filter-group-mode)
 :init
 (setq
  dired-filter-keep-expanded-subtrees nil
  dired-filter-group-saved-groups
  '(("default"
     ("video" (extension "mkv" "avi" "mp4" "webm"))
     ("archives" (extension "zip" "rar" "gz" "bz2" "tar"))
     ("pdf" (extension "pdf"))
     ("tex" (extension "tex" "bib"))
     ("js" (extension "js"))
     ("ts" (extension "ts"))
     ("json" (extension "json"))
     ("styles" (extension "css" "scss" "sass" "less"))
     ("html" (extension "html"))
     ("haskell" (extension "hs"))
     ("idris" (extension "idr"))
     ("purescript" (extension "purs"))
     ("c/c++"
      (extension
       "c" "cc" "cpp" "cxx" "c++"
       "h" "hpp" "hxx" "h++"))
     ("org" (extension "org"))
     ("lisp" (extension "el"))
     ("word" (extension "docx" "doc"))
     ("excel" (extension "xlsx" "xls"))
     ("text" (extension "txt"))
     ("svg" (extension "svg"))
     ("shell"
      (extension
       "sh" "bash" "zsh" "fish" "csh" "ksh"
       "awk" "ps1" "psm1" "psd1" "bat" "cmd"))
     ("audio"
      (extension
       "mp3" "ogg" "flac" "wav"))
     ("img"
      (extension
       "bmp" "jpg" "jpeg" "gif" "png" "tiff"
       "ico" "svg" "psd" "pcd" "raw" "exif")))))
 (nmap 'dired-mode-map
   "/" 'dired-filter-map
   "C-c C-t" 'dired-filter-group-toggle-header
   "C-c C-g" 'dired-filter-group-mode))

(use-package dired-avfs
 :after (dired dired-hack-utils))

(use-package dired-open
 :after (dired dired-hack-utils))

(use-package dired-narrow
 :after (general dired dired-hack-utils)
 :config
 (nmap 'dired-mode-map
   "," 'dired-narrow))

(use-package peep-dired
 :after (dired general)
 :preface
 (defconst my/peep-dired/ignored-extensions
   (append
    my/dired-document-files-extensions
    my/dired-compressed-files-extensions
    my/dired-image-files-extensions
    my/dired-audio-files-extensions
    my/dired-video-files-extensions
    my/dired-misc-files-extensions))
 :hook
 (peep-dired . evil-normalize-keymaps)
 :init
 (setq
  peep-dired-ignored-extensions my/peep-dired/ignored-extensions
  peep-dired-cleanup-on-disable t
  peep-dired-enable-on-directories t)
 :config
 (nmap 'dired-mode-map
   "C-c C-v" 'peep-dired)
 (general-define-key
  :states '(normal)
  :keymaps 'peep-dired-mode-map
  "j" 'peep-dired-next-file
  "k" 'peep-dired-prev-file))

(use-package treemacs
  :defer t
  :init
  (with-eval-after-load 'winum
    (define-key winum-keymap (kbd "M-0") #'treemacs-select-window))
  :config
  (progn
    (setq treemacs-no-png-images t)

    ;; The default width and height of the icons is 22 pixels.
    (treemacs-resize-icons 14)

    (treemacs-follow-mode t)
    (treemacs-filewatch-mode t)
    (treemacs-fringe-indicator-mode 'always)
    (pcase (cons (not (null (executable-find "git")))
                 (not (null treemacs-python-executable)))
      (`(t . t)
       (treemacs-git-mode 'deferred))
      (`(t . _)
       (treemacs-git-mode 'simple))))
  (nmap
    :prefix my/leader
    "r" 'treemacs-select-window
    "q" 'treemacs))

(use-package treemacs-evil
  :after (treemacs evil))

(use-package treemacs-projectile
  :after (treemacs projectile))

(use-package treemacs-magit
  :after (treemacs magit))

(use-package ace-window
 :custom
 (aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l) "Use home row for selecting.")
 (aw-scope 'frame "Highlight only current frame.")
 :config
 (nmap
   :prefix my/leader
   "w" 'ace-window))

(use-package winner
 :demand t
 :init
 (setq
  winner-dont-bind-my-keys t
  winner-boring-buffers
  '("*Completions*"
    "*Compile-Log*"
    "*inferior-lisp*"
    "*Fuzzy Completions*"
    "*Apropos*"
    "*Help*"
    "*cvs*"
    "*Buffer List*"
    "*Ibuffer*"
    "*esh command on file*"))
 :config
 (winner-mode 1)
 :config
 (nmap
   :prefix my/leader
   "U" 'winner-undo
   "R" 'winner-redo)
 (when (eq system-type 'darwin)
   (general-define-key
    "C-s-[" 'winner-undo
    "C-s-]" 'winner-redo)))

(use-package transpose-frame
  :config
  (nmap
    "C-M-SPC" 'transpose-frame
    "C-M-u" 'flip-frame
    "C-M-i" 'flip-frame
    "C-M-y" 'flop-frame
    "C-M-o" 'flop-frame))

(use-package zoom-window
  :custom
  (zoom-window-mode-line-color "#000000")
  :config
  (nmap
    :prefix my/leader
    "RET" 'zoom-window-zoom))

(use-package expand-region
 :after (general)
 :config
 (vmap
   "v" 'er/expand-region)
 (when (eq system-type 'darwin)
   (vmap
     "s-'" 'er/expand-region)))

(use-package ivy
  :preface
  (defun my/ivy/switch-buffer-occur ()
    "Occur function for `ivy-switch-buffer' using `ibuffer'."
    (ibuffer nil (buffer-name) (list (cons 'name ivy--old-re))))
  :commands
  (ivy-mode ivy-set-occur)
  :custom
  (ivy-count-format "%d/%d " "Show anzu-like counter")
  :custom-face
  ;; (ivy-current-match ((t (:inherit 'hl-line))))
  ;; TODO: Make this theme-dependent (use :inherit)
  (ivy-current-match ((t (:background "#333333" :foreground "#fff"))))
  :init
  (setq
   ;; Enable bookmarks and recentf
   ;; (add 'recentf-mode' and bookmarks to 'ivy-switch-buffer')
   ivy-use-virtual-buffers t
   ;; Display full buffer name
   ivy-virtual-abbreviate 'full
   ;; Number of result lines to display
   ivy-height 12
   ;; Current input becomes selectable as a candidate
   ;; solves the issue of creating a file or
   ;; a directory `foo` when a file `foobar` already exists
   ;; another way is to use C-M-j
   ivy-use-selectable-prompt t
   ;; Wrap around ivy results
   ivy-wrap t
   ;; Omit ^ at the beginning of regexp
   ivy-initial-inputs-alist nil)
  :config
  (ivy-mode 1)
  ;; Enable fuzzy searching everywhere except:
  ;; - Switching buffers with Ivy
  ;; - Swiper
  ;; - Counsel projectile (find-file)
  (setq
   ivy-re-builders-alist
   '((swiper . ivy--regex-plus)
     (swiper-isearch . regexp-quote)
     (ivy-switch-buffer . ivy--regex-plus)
     (counsel-projectile-find-file . ivy--regex-plus)))
  (ivy-set-occur 'ivy-switch-buffer 'my/ivy/switch-buffer-occur)
  (nmap
    :prefix my/leader
    "b" 'ivy-switch-buffer)
  (nmap
    "C-c v" 'ivy-push-view
    "C-c V" 'ivy-pop-view)
  (when (eq system-type 'darwin)
    (general-define-key
     "s-b" 'ivy-switch-buffer
     "M-s-b" 'ivy-resume))
  (general-define-key
   :keymaps 'ivy-minibuffer-map
   "C-t" 'ivy-toggle-fuzzy
   "C-j" 'ivy-next-line
   "C-k" 'ivy-previous-line
   "C-n" 'ivy-next-history-element
   "C-p" 'ivy-previous-history-element
   "<C-return>" 'ivy-immediate-done
   "C-l" 'ivy-immediate-done
   "C-w" 'ivy-backward-kill-word)
  :diminish ivy-mode)

(use-package ivy-rich
 :after ivy
 :commands
 ivy-rich-mode
 :init
 (setq
  ;; To abbreviate paths using abbreviate-file-name
  ;; (e.g. replace “/home/username” with “~”)
  ivy-rich-path-style 'abbrev)
 :config
 (ivy-rich-mode 1))

(use-package ivy-xref
 :init
  ;; xref initialization is different in Emacs 27 - there are two different
  ;; variables which can be set rather than just one
  (when (>= emacs-major-version 27)
    (setq xref-show-definitions-function #'ivy-xref-show-defs))
  ;; Necessary in Emacs <27. In Emacs 27 it will affect all xref-based
  ;; commands other than xref-find-definitions (e.g. project-find-regexp)
  ;; as well
  (setq xref-show-xrefs-function #'ivy-xref-show-xrefs))

(use-package flyspell-correct-ivy
 :after (general flyspell ivy)
 :demand t
 :init
 (setq flyspell-correct-interface 'flyspell-correct-ivy)
 :config
 (nmap 'flyspell-mode-map
   "C-;" 'flyspell-correct-next))

(use-package ibuffer-vc
  :custom
  (ibuffer-formats
   '((mark modified read-only vc-status-mini " "
           (name 18 18 :left :elide)
           " "
           (size 9 -1 :right)
           " "
           (mode 16 16 :left :elide)
           " "
           filename-and-process)) "include vc status info")
  :hook
  (ibuffer . (lambda ()
               (ibuffer-vc-set-filter-groups-by-vc-root)
               (unless (eq ibuffer-sorting-mode 'alphabetic)
                 (ibuffer-do-sort-by-alphabetic)))))

(use-package fzf)

(use-package counsel
 :after general
 :init
 ;; Much faster than grep
 (setq
  counsel-git-cmd "rg --files"
  ;; Truncate all lines that are longer than 120 characters
  counsel-grep-base-command
  "rg -i -M 120 --no-heading --line-number --color never %s .")
 :config
 (nmap
   "C-f" 'counsel-imenu)
 (imap
   "C-," 'counsel-unicode-char)
 (nmap
   :prefix my/leader
   "f" 'counsel-rg
   "F" 'counsel-fzf
   "h v" 'counsel-describe-variable
   "h f" 'counsel-describe-function
   "h F" 'counsel-describe-face)
 (when (eq system-type 'darwin)
   (nmap
     "s-f" 'counsel-rg))
 (nmap
   "M-x" 'counsel-M-x)
 (nmap
   :prefix "C-x"
   "C-r" 'find-file
   "C-f" 'counsel-find-file
   "C-g" 'counsel-git-grep
   "p" 'counsel-package)
 (nmap
   :prefix my/leader
   my/leader 'counsel-M-x
   "T" 'counsel-load-theme
   "J" 'counsel-bookmark))

(use-package ace-link
 :after (counsel)
 :commands
 (ace-link-setup-default)
 :config
 (nmap
   "C-c C-l" 'counsel-ace-link)
 :config
 (ace-link-setup-default))

(use-package counsel-etags
  :after (general counsel)
  :init
  ;; Don't ask before rereading the TAGS files if they have changed
  (setq tags-revert-without-query t)
  ;; Don't warn when TAGS files are large
  (setq large-file-warning-threshold nil)
  ;; (setq counsel-etags-extra-tags-files '("./codex.tags"))
  ;; Use a custom command to update tags
  ;; (setq counsel-etags-update-tags-backend
  ;;       (lambda (src-dir) (shell-command "make tags")))
  :config
  (nmap
    "C-]" 'counsel-etags-find-tag-at-point)
  :init
  (add-hook 'prog-mode-hook
    (lambda ()
      (add-hook 'after-save-hook
        'counsel-etags-virtual-update-tags 'append 'local)))
  :config
  ;; (with-eval-after-load 'counsel-etags
  ;;   (push "TAGS" counsel-etags-ignore-filenames)
  ;;   (push "build" counsel-etags-ignore-directories))
  (setq counsel-etags-update-interval 60))

(use-package swiper
  :after general
  :init
  ;; Recenter after swiper is finished
  (setq swiper-action-recenter t)
  :config
  (general-define-key
   :keymaps 'swiper-map
   "C-r" 'swiper-query-replace)
  (general-define-key
   :keymaps 'ivy-mode-map
   "C-k" 'ivy-previous-line)
  (nmap
    "C-s" 'swiper))

(use-package dumb-jump
 :custom
 (dumb-jump-selector 'ivy)
 (dumb-jump-prefer-searcher 'ag)
 (nmap
   "C-c C-j" 'dumb-jump-go))

(use-package avy
 :config
 (mmap
   :prefix "C-c j"
   "c" 'avy-goto-char
   "w" 'avy-goto-word-1
   "l" 'avy-goto-line))

(use-package avy-flycheck
 :after (general avy flycheck)
 :commands
 avy-flycheck-setup
 :init
 (setq avy-flycheck-style 'pre)
 :config
 (avy-flycheck-setup)
 (nmap
   :prefix my/leader
   "n e" 'avy-flycheck-goto-error))

(use-package navigate
 :quelpa
 (navigate :fetcher github :repo "keith/evil-tmux-navigator")
 :config
 (require 'navigate))

(use-package projectile
 :after (general ivy)
 :init
 ;; Projectile requires this setting for ivy completion
 (setq
  projectile-indexing-method 'alien
  projectile-completion-system 'ivy
  ;; Useful for very large projects
  projectile-enable-caching t
  projectile-sort-order 'recently-active
  projectile-mode-line nil
  projectile-use-git-grep t
  projectile-file-exists-remote-cache-expire (* 10 60)
  projectile-file-exists-local-cache-expire (* 5 60)
  projectile-require-project-root nil
  projectile-globally-ignored-directories
  '(".git" ".svn" ".hg" "_darcs"
    "out" "output" "repl"
    "dist" "dist-newstyle"
    ".vagrant"
    "project" "target" "compiled" ".bundle"
    "*build" "jar"
    "venv" ".virtualenv"
    "*__pycache__*" "*.egg-info"
    ".tox" ".cache" ".cabal-sandbox" ".stack-work"
    ".emacs.d" "elpa" "site-lisp"
    "bin" "eclipse-bin" ".ensime_cache" ".idea"
    ".eunit" ".bzr"
    "vendor" "uploads" "assets"
    "node_modules" "bower_components"
    "_build" ".psci_modules" ".pulp-cache")
  projectile-globally-ignored-files
  '(".DS_Store" "TAGS" ".nrepl-port" "*.gz" "*.pyc" ".purs-repl"
    "*.jar" "*.tar.gz" "*.tgz" "*.zip" "package-lock.json"))
 :config
 ;; Use projectile everywhere
 (projectile-mode)
 ;; Remove the mode name for projectile-mode, but show the project name
 ;; :delight '(:eval (concat " " (projectile-project-name)))
 (nmap
   :prefix my/leader
   "!" 'projectile-run-async-shell-command-in-root
   "DEL" 'projectile-invalidate-cache)
 (nmap
   "C-SPC SPC" 'projectile-commander)
 :diminish projectile-mode)

(use-package counsel-projectile
 :after (counsel projectile general)
 :config
 (nmap
   "C-q" 'counsel-projectile-find-file
   "C-a" 'counsel-projectile-switch-to-buffer
   "C-p" 'counsel-projectile-switch-project))

(use-package with-editor
 :config
 (nmap 'with-editor-mode-map
   ;; it closes the Magit's git-commit window
   ;; instead of switching to evil-normal-state
   ;; [escape] 'with-editor-cancel
   "RET" 'with-editor-finish)
 (evil-set-initial-state 'with-editor-mode 'insert))

(use-package git-messenger
  :config
  (nmap
    :prefix my/leader
    "g m" 'git-messenger:popup-message))

(use-package magit
  :demand t
  :custom
  (magit-log-buffer-file-locked t)
  (magit-refs-show-commit-count 'all)
  (magit-save-repository-buffers 'dontask)
  (git-messenger:use-magit-popup t)
  :config
  ;; Unset pager as it is not supported properly inside emacs
  (setenv "GIT_PAGER" "")
  (nmap
    :prefix my/leader
    "g s" 'magit-status
    "g S" 'magit-stash
    "g l" 'magit-log
    "g B" 'magit-blame
    "g p" 'magit-pull
    "g P" 'magit-push
    "g b c" 'magit-branch-checkout
    "g b n" 'magit-branch-create
    "g c c" 'magit-commit-create
    "g c a" 'magit-commit-amend
    "g d d" 'magit-diff
    "g d f" 'magit-diff-buffer-file))

(use-package forge)

(use-package git-gutter
 :after (general)
 :demand t
 :commands
 (global-git-gutter-mode)
 :config
 ;; (global-git-gutter-mode)
 ;; (git-gutter:linum-setup)
 (custom-set-variables
  '(git-gutter:update-interval 2)
  '(git-gutter:modified-sign "*")
  '(git-gutter:added-sign "+")
  '(git-gutter:deleted-sign "-")
  '(git-gutter:hide-gutter nil))
 (set-face-foreground 'git-gutter:modified "#da8548")
 (set-face-foreground 'git-gutter:added "#98be65")
 (set-face-foreground 'git-gutter:deleted "#ff6c6b")
 (nmap
   :prefix my/leader
   "t g" 'git-gutter-mode)
 :diminish git-gutter-mode)

(use-package git-timemachine
  :config
  (nmap
    :prefix my/leader
    "g t" 'git-timemachine))

(use-package git-modes)

(use-package gist
 :after general
 :config
 (nmap
   :prefix my/leader
   "G l" 'gist-list
   "G b" 'gist-buffer
   "G B" 'gist-buffer-private
   "G r" 'gist-region
   "G R" 'gist-region-private))

(setenv "LESS" "--dumb --prompt=s")
(setenv "PAGER" "")

  (use-package eshell
    :ensure nil
    ;; :config
    ;; (unbind-key "C-j" eshell-mode-map)
    ;; (unbind-key "C-k" eshell-mode-map)
  )

(use-package esh-help
 :commands
 (setup-esh-help-eldoc)
 :config
 (setup-esh-help-eldoc))

(use-package esh-autosuggest
 :hook (eshell-mode . esh-autosuggest-mode))

(use-package eshell-prompt-extras
 :after esh-opt
 :commands
 (epe-theme-dakrone)
 :custom
 (eshell-prompt-function #'epe-theme-dakrone))

(use-package eshell-fringe-status
  :hook
  (eshell-mode . eshell-fringe-status-mode))

(use-package eshell-toggle
 :after (general)
 :custom
 (eshell-toggle-use-projectile-root t)
 (eshell-toggle-run-command nil)
 :config
 (nmap
   :prefix my/leader
   "\\" 'eshell-toggle))

(use-package yasnippet
  :demand t
  :init
  (setq
   yas-wrap-around-region t
   yas-indent-line t)
  :config
  (yas-global-mode 1)
  (nmap
    :prefix my/leader
    "y i" 'yas-insert-snippet
    "y n" 'yas-new-snippet
    "y v" 'yas-visit-snippet-file
    "y r" 'yas-reload-all)
  (imap
    "C-l" 'yas-insert-snippet)
  :diminish yas-minor-mode)

(use-package ivy-yasnippet
 :config
 (imap
   "C-s" 'ivy-yasnippet))

(use-package auto-yasnippet
 :after (general yasnippet)
 :config
 (nmap
   :prefix my/leader
   "y c" 'aya-create
   "y e" 'aya-expand
   "y o" 'aya-open-line))

(use-package yasnippet-snippets)

(use-package yatemplate
  :init
  (yatemplate-fill-alist))

(use-package org
  :after (general counsel)
  :mode ("\\.org\\'" . org-mode)
  :commands
  (org-babel-do-load-languages)
  :init

(setq org-startup-indented t)
(setq org-startup-folded t)
(setq org-catch-invisible-edits 'error)

(setq org-startup-with-inline-images t)

(setq org-export-with-smart-quotes t)

(setq org-enforce-todo-dependencies t)

(setq org-pretty-entities t)

(setq org-log-done 'time)

(setq org-log-redeadline (quote time))

(setq org-log-reschedule (quote time))

(setq org-hide-leading-stars t)

(setq org-src-fontify-natively t)

(setq org-ellipsis "…")

(setq
 org-directory "~/Dropbox/org"
 org-agenda-files '("~/Dropbox/org/"))

(setq
 org-refile-targets
 (quote ((nil :maxlevel . 9)
  (org-agenda-files :maxlevel . 9))))

(setq org-src-tab-acts-natively t)
(setq org-src-preserve-indentation t)
(setq org-src-fontify-natively t)

(setq org-log-into-drawer t)

(setq
 org-file-apps
 (quote
  ((auto-mode . emacs)
   ("\\.mm\\'" . default)
   ("\\.x?html?\\'" . "google-chrome %s")
   ("\\.pdf\\'" . default))))

(setq
 org-capture-templates
 '(("t" "todo" entry (file "todo.org") "* TODO %^{task name}\n%u\n%a\n")
   ("n" "note" entry (file "notes.org") "* %^{heading} %t %^g\n  %?\n")
   ("j" "journal" entry (file "journal.org") "* %U - %^{heading}\n  %?")))

  (defun org-mode-export-links ()
    "Export links document to HTML automatically when 'links.org' is changed"
    (when (equal (buffer-file-name) "~/Dropbox/org/links.org")
      (progn
        (org-html-export-to-html)
        (alert "HTML exported" :severity 'trivial :title "ORG"))))

  (add-hook 'after-save-hook 'org-mode-export-links)

(setq
 org-highest-priority ?A
 org-lowest-priority ?C
 org-default-priority ?B)

(setq
  org-todo-keywords
  '((sequence "TODO" "IN-PROGRESS" "WAITING" "HOLD" "|" "DONE" "CANCELLED"))
  org-todo-keyword-faces
  '(("TODO" :foreground "magenta2" :weight bold)
    ("IN-PROGRESS" :foreground "dodger blue" :weight bold)
    ("WAITING" :foreground "orange" :weight bold)
    ("DONE" :foreground "forest green" :weight bold)
    ("HOLD" :foreground "magenta" :weight bold)
    ("CANCELLED" :foreground "forest green" :weight bold)
    ("BUG" :foreground "red" :weight bold)
    ("UNTESTED" . "purple"))
  org-todo-state-tags-triggers
  '(("CANCELLED" ("CANCELLED" . t))
    ("WAITING" ("WAITING" . t))
    ("HOLD" ("WAITING") ("HOLD" . t))
    (done ("WAITING") ("HOLD"))
    ("TODO" ("WAITING") ("CANCELLED") ("HOLD"))
    ("IN-PROGRESS" ("WAITING") ("CANCELLED") ("HOLD"))
    ("DONE" ("WAITING") ("CANCELLED") ("HOLD"))))

(setq org-agenda-dim-blocked-tasks nil)

(setq org-agenda-compact-blocks t)

(setq
 org-agenda-skip-scheduled-if-done t
 org-agenda-skip-deadline-if-done t)

(setq
 org-agenda-start-day "-3d"
 org-agenda-span 30)

(setq org-agenda-show-all-dates nil)

(setq org-deadline-warning-days 0)

(setq org-agenda-use-time-grid nil)

(setq
 org-agenda-prefix-format
 '((agenda . " %i %-12t% s %b\n")
   (timeline . "  % s")
   (todo . " %i %-12:c")
   (tags . " %i %-12:c")
   (search . " %i %-12:c")))

:config
(require 'org)

(setq
 org-format-latex-options
 (plist-put org-format-latex-options :scale 1.7))

(nmap 'org-mode-map
 "C-k" 'windmove-up
 "C-j" 'windmove-down)

(nmap
  :prefix my/leader
  "t L" 'org-toggle-link-display
  "o" 'org-todo-list
  "O" 'counsel-org-goto-all
  "c" 'counsel-org-capture
  "k" 'org-narrow-to-subtree)
(mmap 'org-agenda-mode-map
  "C-c C-l" 'org-agenda-log-mode)
:delight "org")

;; See: https://github.com/Somelauw/evil-org-mode/issues/93#issuecomment-950306532
(fset 'evil-redirect-digit-argument 'ignore)

(use-package evil-org
 :after (general org)
 :commands
 (evil-org-set-key-theme evil-org-agenda-set-keys)
 :preface
 (defun my/evil-org/setup ()
   (evil-org-mode)
   (evil-org-set-key-theme '(textobjects insert navigation additional shift todo heading calendar))
   (evil-org-agenda-set-keys))
 :hook
 (org-mode . my/evil-org/setup)
 :config
 (add-to-list 'evil-digit-bound-motions 'evil-org-beginning-of-line)
 (evil-define-key 'motion 'evil-org-mode
   (kbd "0") 'evil-org-beginning-of-line)
 (require 'evil-org-agenda)
 :diminish evil-org-mode)

(use-package org-superstar
 :after (org)
 :config
 (org-superstar-configure-like-org-bullets)
 :hook
 (org-mode . org-superstar-mode))

    (use-package org-sticky-header
    :after (org)
    :hook
    (org-mode . org-sticky-header-mode))

(use-package org-cliplink
  :config
  (nmap 'org-mode-map
    :prefix my/leader
    "L" 'org-cliplink))

(use-package org-roam
:after (general org)
:demand t
:preface
(defun my/org-roam/node-insert-immediate (arg &rest args)
  (interactive "P")
  (let ((args (cons arg args))
        (org-roam-capture-templates (list (append (car org-roam-capture-templates)
                                                  '(:immediate-finish t)))))
    (apply #'org-roam-node-insert args)))
(defun my/org-roam/filter-by-tag (tag-name)
  (lambda (node)
    (member tag-name (org-roam-node-tags node))))
(defun my/org-roam/list-notes-by-tag (tag-name)
  (mapcar #'org-roam-node-file
          (seq-filter
           (my/org-roam/filter-by-tag tag-name)
           (org-roam-node-list))))
(defun my/org-roam/refresh-agenda-list ()
  (interactive)
  (setq org-agenda-files (my/org-roam/list-notes-by-tag "agenda")))
(defun my/org-roam/setup ()
 (my/org-roam/refresh-agenda-list))
:custom
(org-roam-directory "~/projects/personal/braindump/org")
(org-roam-capture-templates
 '(("d" "default" plain "%?"
     :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n")
     :unnarrowed t)
   ("b" "book notes" plain
    "\n* Source\n\nAuthor: %^{Author}\nTitle: ${title}\nYear: %^{Year}\n\n* Summary\n\n%?"
    :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n")
    :unnarrowed t)
   ("p" "project" plain "* Goals\n\n%?\n\n* Tasks\n\n** TODO Add initial tasks\n\n* Dates\n\n"
    :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+category: ${title}\n#+filetags: project agenda")
    :unnarrowed t)))
:init
(setq org-roam-v2-ack t)
(setq org-roam-dailies-directory "journal/")
(setq org-roam-dailies-capture-templates
      '(("d" "default" entry
         "* %<%H:%M> %?"
         :target (file+head+olp "%<%Y-%m-%d>.org"
                                "#+title: %<%Y-%m-%d>\n" ("Journal")))))
:hook
(org-mode . my/org-roam/setup)
:config
;; Ensure the keymap is available
(require 'org-roam-dailies)
(org-roam-setup)
(org-roam-db-autosync-mode)
(nmap
  :prefix my/leader
  "n l" 'org-roam-buffer-toggle
  "n f" 'org-roam-node-find
  "n i" 'org-roam-node-insert
  "n j" 'org-roam-dailies-capture-today
  "n k" 'org-roam-dailies-capture-tomorrow
  "n h" 'org-roam-dailies-capture-yesterday
  "n d" 'org-roam-dailies-goto-today
  "n y" 'org-roam-dailies-goto-yesterday
  "n t" 'org-roam-dailies-goto-tomorrow
  "n D" 'org-roam-dailies-goto-date
  "n ," 'org-roam-dailies-goto-previous-note
  "n ." 'org-roam-dailies-goto-next-note))

(use-package ox-hugo
  :after (ox org-capture)
  :commands (org-hugo-slug)
  :custom
  (org-hugo-delete-trailing-ws nil)
  :config
  ;; Define variable to get rid of 'reference to free variable' warnings.
  (defun my/org-hugo/new-subtree-post ()
    "Returns `org-capture' template string for new blog post.
     See `org-capture-templates' for more information."
    (let*
        ;; Prompt to enter the post title
        ((title (read-from-minibuffer "Post Title: "))
         (lang (read-from-minibuffer "Lang code (e.g. ru-ru): "))
         (date (format-time-string (org-time-stamp-format :long :inactive) (org-current-time)))
         (fname (concat (org-hugo-slug title) "." lang)))
      (mapconcat
       #'identity
       `(
         ,(concat "* TODO " title)
         ":PROPERTIES:"
         ,(concat ":EXPORT_FILE_NAME: " fname)
         ,(concat ":EXPORT_DATE: " date) ;Enter current date and time
         ":END:"
         "%?\n") ; Place the cursor here finally
       "\n")))
  ;; org-capture template to quickly create posts and generate slugs.
  (add-to-list
   'org-capture-templates
   '("b"
     "blog post"
     entry
     (file "~/projects/personal/blog/content-org/posts.org")
     (function my/org-hugo/new-subtree-post))))

(use-package lsp-mode
  :after (general projectile)
  :commands (lsp)
  :hook
  (lsp-mode . lsp-lens-mode)
  (lsp-mode . lsp-enable-which-key-integration)
  (c-mode . lsp)
  (c++-mode . lsp)
  :init
  ;; Uncomment to inspect communication between client and the server
  (setq lsp-print-io t)
  (setq lsp-prefer-flymake nil)
  (setq lsp-headerline-breadcrumb-enable t)
  :config
  ;; Determines how often lsp-mode will refresh the highlights, lenses, links, etc while you type.
  (setq lsp-idle-delay 0.500)
  ;; Make sure the logging is switched off
  (setq lsp-log-io nil)
  (setq lsp-completion-provider :capf)
  ;; What to use when checking on-save: "check" is default, I prefer "clippy"
  (setq lsp-rust-analyzer-cargo-watch-command "clippy")
  (setq lsp-rust-analyzer-server-display-inlay-hints t)
  (dolist (dir '("vendor")) (push dir lsp-file-watch-ignored))
  (nmap
    :prefix my/leader
    "l r" 'lsp-restart-workspace
    "l f" 'lsp-format-buffer
    "l d" 'lsp-describe-thing-at-point)
  :delight "lsp")

(use-package lsp-ui
  :after (lsp-mode)
  :commands (lsp-ui-mode general)
  :config
  (add-hook 'lsp-mode-hook 'lsp-ui-mode)
  (add-hook 'lsp-after-open-hook 'lsp-enable-imenu)
  (add-hook 'lsp-ui-doc-frame-hook
    (lambda (frame _w)
      (set-face-attribute 'default frame :font "JetBrains Mono" :height 12)))
  (set-face-attribute 'lsp-ui-sideline-global nil :font "JetBrains Mono" :height 0.6)
  (set-face-attribute 'lsp-ui-sideline-code-action nil :font "JetBrains Mono" :height 0.6)
  (setq
   ;; Show side line (e.g. code actions hits)
   lsp-ui-sideline-enable t
   lsp-ui-sideline-show-hover t
   lsp-ui-sideline-delay 0.5
   lsp-ui-peek-always-show t
   lsp-ui-sideline-actions-icon nil
   ;; Show hover messages in sideline
   lsp-ui-show-hover t
   ;; Show code actions in sideline
   lsp-ui-show-code-actions nil
   lsp-enable-completion-at-point t
   lsp-ui-doc-position 'at-point
   lsp-ui-doc-header nil
   lsp-ui-doc-enable nil
   lsp-ui-doc-delay 0.25
   lsp-ui-doc-use-webkit nil
   lsp-ui-doc-include-signature t
   lsp-ui-doc-border "#222"
   lsp-ui-peek-fontify nil
   lsp-ui-peek-expand-function (lambda (xs) (mapcar #'car xs)))
  (nmap 'lsp-ui-mode-map
    :prefix my/leader
    "=" 'lsp-ui-sideline-apply-code-actions)
  (nmap 'haskell-mode-map
    :prefix my/leader
    "i" 'lsp-ui-doc-focus-frame
    "I" 'lsp-ui-imenu
    "t d" 'lsp-ui-doc-mode
    "t s" 'lsp-ui-sideline-mode)
  (general-def 'lsp-ui-peek-mode-map
    "h" 'lsp-ui-peek--select-next-file
    "l" 'lsp-ui-peek--select-prev-file
    "j" 'lsp-ui-peek--select-next
    "k" 'lsp-ui-peek--select-prev))

(use-package company-lsp
 :after (lsp-mode company)
 ;; It is not on MELPA yet:
 ;; https://github.com/tigersoldier/company-lsp/issues/147
 :quelpa
 (company-lsp :fetcher github :repo "tigersoldier/company-lsp")
 :commands (company-lsp)
 :init
 (setq
  ;; Don't filter results on the client side
  company-transformers nil
  company-lsp-cache-candidates 'auto
  ;; Fetch completion candidates asynchronously.
  company-lsp-async t
  ;; Enable snippet expansion on completion
  company-lsp-enable-snippet t)
 :config
 (push 'company-lsp company-backends))

(use-package lsp-treemacs
 :after (general)
 :commands lsp-treemacs-errors-list
 :config
 ;; Enable bidirectional synchronization of lsp workspace
 ;; folders and treemacs projects
 (lsp-treemacs-sync-mode 1)
 (nmap
   :prefix my/leader
   "m s" 'lsp-treemacs-symbols
   "m r" 'lsp-treemacs-references
   "m i" 'lsp-treemacs-implementations
   "m c" 'lsp-treemacs-call-hierarchy
   "m t" 'lsp-treemacs-type-hierarchy
   "m e" 'lsp-treemacs-errors-list))

(use-package lsp-ivy)

(use-package makefile-executor
  :config
  (add-hook 'makefile-mode-hook 'makefile-executor-mode))

(use-package rfc-mode
 :custom
  rfc-mode-directory (my/emacs-path "rfc"))

(use-package helpful
 :config
 (nmap
   :prefix my/leader
   "H h" 'helpful-at-point
   "H f" 'helpful-callable
   "H F" 'helpful-function
   "H v" 'helpful-variable
   "H c" 'helpful-command
   "H k" 'helpful-key))

(use-package devdocs
  :config
  (nmap
    :prefix my/leader
    "h h" 'devdocs-search))

(use-package mmm-mode
  :after (haskell-mode)
  :preface
  (defun my/mmm-mode/setup ()
    ;; go into mmm minor mode when class is given
    (make-local-variable 'mmm-global-mode)
    (setq mmm-global-mode 'true))
  :init
  (setq mmm-submode-decoration-level 1)
  :hook
  (haskell-mode . my/mmm-mode/setup)
  :config

(mmm-add-classes
 '((literate-haskell-bird
    :submode text-mode
    :front "^[^>]"
    :include-front true
    :back "^>\\|$")
   (literate-haskell-latex
    :submode literate-haskell-mode
    :front "^\\\\begin{code}"
    :front-offset (end-of-line 1)
    :back "^\\\\end{code}"
    :include-back nil
    :back-offset (beginning-of-line -1))))

(setq mmm-submode-decoration-level 0)

(setq mmm-parse-when-idle 't))

(use-package lisp-mode
  :ensure nil
  :config
  (put 'use-package 'lisp-indent-function 1)
  (put 'add-hook 'lisp-indent-function 1)
  (put :map 'lisp-indent-function 1))

(use-package elisp-mode
  :after (general company smartparens)
  :ensure nil
  :preface
  (defun my/emacs-lisp-prettify-symbols-setup ()
    "Prettify `emacs-lisp-mode' specific symbols."
    (dolist (symbol '(("defun"    . ?ƒ)
                      ("defmacro" . ?μ)
                      ("defvar"   . ?ν)
                      ("defconst" . "ν_")))
      (cl-pushnew symbol prettify-symbols-alist :test #'equal)))
  :config
  (nmap 'emacs-lisp-mode-map
    "M-." 'find-function-at-point
    "M-," 'find-variable-at-point)
  (add-to-list 'company-backends 'company-elisp)
  (sp-with-modes 'emacs-lisp-mode
    (sp-local-pair "'" nil :actions nil))
  :hook
  (emacs-lisp-mode . my/emacs-lisp-prettify-symbols-setup))

(use-package elisp-refs
  :after elisp-mode)

(use-package macrostep
 :after elisp-mode
 :demand t
 :commands macrostep-expand
 :mode ("\\*.el\\'" . emacs-lisp-mode)
 :config
 ;; support Macrostep in Evil mode
 (general-define-key
  :keymaps 'macrostep-keymap
  "q" 'macrostep-collapse-all
  "e" 'macrostep-expand)
 (nmap
   :keymaps 'emacs-lisp-mode-map
   :prefix my/leader
   "m e" 'macrostep-expand))

(use-package highlight-defined
 :custom
 (highlight-defined-face-use-itself t)
 :hook
 (emacs-lisp-mode . highlight-defined-mode))

(use-package highlight-quoted
 :hook
 (emacs-lisp-mode . highlight-quoted-mode))

(use-package highlight-sexp
  :quelpa
  (highlight-sexp :repo "daimrod/highlight-sexp" :fetcher github :version original)
  :hook
  (emacs-lisp-mode . highlight-sexp-mode)
  (lisp-mode . highlight-sexp-mode))

(use-package eros
 :hook
 (emacs-lisp-mode . eros-mode))

(use-package ipretty
  :defer t
  :commands
  (ipretty-mode)
  :config
  (ipretty-mode 1))

(use-package nameless
 :hook
 (emacs-lisp-mode . nameless-mode)
 :custom
 (nameless-global-aliases '())
 (nameless-private-prefix t)
 :config
 (nmap 'emacs-lisp-mode-map
   :prefix my/leader
   "t n" 'nameless-mode))

(use-package easy-escape
  :diminish easy-escape-minor-mode
  :hook
  (emacs-lisp-mode . easy-escape-minor-mode))

(use-package package-lint)

(use-package flycheck-package
 :defer t
 :after flycheck
 (flycheck-package-setup))

(use-package suggest
  :preface
  (defun my/suggest-popup ()
    "Open suggest as a popup."
    (interactive)
    (let* ((window (selected-window))
           (dedicated-flag (window-dedicated-p window)))
      (set-window-dedicated-p window t)
      (suggest)
      (set-window-dedicated-p window dedicated-flag)))
  :config
  (nmap 'emacs-lisp-mode-map
    :prefix my/leader
    "E s" 'my/suggest-popup))

(use-package hasklig-mode
  :commands
  (hasklig-mode)
  :delight "hl")

(use-package haskell-mode
  :after
  (general company eldoc)
  ;; :quelpa
  ;; (haskell-mode :fetcher github :repo "haskell/haskell-mode")
  :mode
  (("\\.hs\\(-boot\\)?\\'" . haskell-mode)
   ("\\.hcr\\'" . haskell-core-mode)
   ("\\.lhs\\'" . literate-haskell-mode)
   ("\\.cabal\\'" . haskell-cabal-mode)
   ("\\.x\\'" . prog-mode))
  :commands
  (haskell-compile-cabal-build-command
   haskell-interactive-mode-map)
  :preface
  (defun my/display-ctrl-D-as-space ()
    "Display `^D' as newline."
    (interactive)
    (setq buffer-display-table (make-display-table))
    (aset buffer-display-table ?\^D [?\ ]))
  (defun my/haskell-mode/setup ()
    (interactive)
    ;; (setq buffer-face-mode-face '(:family "Hasklig"))
    (buffer-face-mode)
    ;; Treat symbol (e.g. "_") as a word
    (defalias 'forward-evil-word 'forward-evil-symbol)
    ;; (subword-mode 1)
    ;; (eldoc-overlay-mode)       ; annoying
    ;; (haskell-indentation-mode) ; hi2 FTW
    ;; Affects/breaks haskell-indentation-mode
    ;; (setq-local evil-auto-indent nil)
    (with-current-buffer (get-buffer-create "*haskell-process-log*")
      (my/display-ctrl-D-as-space))
    ;; (hasklig-mode)
    (haskell-doc-mode)
    (haskell-collapse-mode)
    (haskell-decl-scan-mode)
    (electric-layout-mode)
    (electric-pair-local-mode)
    (electric-indent-local-mode)
    ;; There are some tools that dont't work with unicode symbols
    ;; I (sometimes) use Hasklig instead
    ;; (turn-on-haskell-unicode-input-method)
    (face-remap-add-relative 'font-lock-doc-face 'font-lock-comment-face))
  (defvar my/haskell-process-use-ghci nil)
  (defvar my/haskell-build-command-use-make nil)
  (defun my/haskell-mode/toggle-build-command ()
    "Toggle the build command"
    (interactive)
    (if my/haskell-build-command-use-make
        (progn
          (setq haskell-compile-cabal-build-command "cd %s && cabal new-build")
          (alert "Setting build command to:\n cabal new-build" :severity 'normal :title "Haskell"))
      (progn
        (setq haskell-compile-cabal-build-command "cd %s && make build")
        (alert "Setting build command to:\n make build" :severity 'normal :title "Haskell"))))
  (defun my/haskell-mode/toggle-process-type ()
    "Toggle GHCi process between cabal and ghci"
    (interactive)
    (if my/haskell-process-use-ghci
        (progn
          ;; You could set it to "cabal-repl" if
          ;; you're using the old cabal workflow
          (setq haskell-process-type 'cabal-new-repl)
          (setq my/haskell-process-use-ghci nil)
          (alert "Using cabal new-repl" :severity 'normal :title "Haskell"))
      (progn
        (setq haskell-process-type 'stack-ghci)
        (setq my/haskell-process-use-ghci t)
        (alert "Using stack ghci" :severity 'normal :title "Haskell"))))
  (defun my/haskell-mode/show-process-log ()
    "Display *haskell-process-log* buffer in other window"
    (interactive)
    (switch-to-buffer-other-window "*haskell-process-log*"))
  :hook
  (haskell-mode . my/haskell-mode/setup)
  :custom
  ;; Enable debug logging to *haskell-process-log* buffer
  (haskell-process-log t)
  ;; Don't generate tags via hasktags after saving
  (haskell-tags-on-save nil)
  ;; Don't run stylish-haskell on the buffer before saving.
  ;; It just inserts a bunch of spaces at the end of the line for no reason
  (haskell-stylish-on-save nil)
  ;; Suggest to add import statements using Hoogle as a backend
  (haskell-process-suggest-hoogle-imports t)
  ;; Suggest to add import statements using Hayoo as a backend
  (haskell-process-suggest-hayoo-imports t)
  ;; Replace SVG image text with actual images
  (haskell-svg-render-images t)
  ;; Don't eliminate the context part in a Haskell type
  (haskell-doc-chop-off-context nil)
  ;; Suggest removing import lines as warned by GHC
  (haskell-process-suggest-haskell-docs-imports t)
  ;; Search for the types of global functions by loading the files
  (haskell-doc-show-global-types t)
  ;; Don't show debugging tips when starting the process
  (haskell-process-show-debug-tips nil)
  ;; Don’t suggest removing import lines as warned by GHC
  ;; It is too annoying, sometimes I want to keep unused imports
  (haskell-process-suggest-remove-import-lines nil)
  ;; Don't suggest adding packages to .cabal file
  (haskell-process-suggest-add-package nil)
  ;; Don't suggest restarting the f*****g process
  (haskell-process-suggest-restart nil)
  ;; Don't suggest adding the OverloadedStrings extensions
  (haskell-process-suggest-overloaded-strings nil)
  ;; Auto import the modules reported by GHC to have been loaded
  (haskell-process-auto-import-loaded-modules t)
  ;; Show things like type info instead of printing to the message area
  ;; haskell-process-use-presentation-mode t
  ;; Don't popup errors in a separate buffer
  (haskell-interactive-popup-errors nil)
  ;; Make haskell-process-log look better
  (haskell-process-args-ghci '("-ferror-spans" "-fhide-source-paths"))
  (haskell-process-args-cabal-repl '("--ghc-options=-ferror-spans -fhide-source-paths"))
  (haskell-process-args-stack-ghci '("--ghci-options=-ferror-spans" "--no-build" "--no-load"))
  (haskell-process-args-cabal-new-repl '("--ghc-options=-ferror-spans -fhide-source-paths"))
  ;; Use "cabal new-repl" as the inferior haskell process
  (haskell-process-type 'cabal-new-repl)
  ;; haskell-process-args-stack-ghci '("--ghci-options=-ferror-spans")
  ;; haskell-compile-cabal-build-command "stack build --no-library-profiling"
  (haskell-compile-cabal-build-command "cd %s && cabal new-build")
  :config
  (add-to-list
   'electric-layout-rules
   '((?\{) (?\} . around)))
  (add-to-list
   'electric-layout-rules
   '((?\[) (?\] . around)))
  ;; Common key bindings
  (nmap '(haskell-mode-map haskell-cabal-mode-map haskell-interactive-mode-map)
    "C-c C-b" 'haskell-compile
    "C-c C-k" 'haskell-interactive-mode-kill
    "C-c C-r" 'haskell-process-restart
    "C-c C-d" 'haskell-cabal-add-dependency
    "C-c C-l" 'haskell-interactive-mode-clear
    "C-c C-h" 'haskell-hoogle
    "C-c SPC" 'haskell-session-change-target
    "C-c C-c" 'my/haskell-mode/show-process-log)
  (nmap '(haskell-mode-map haskell-cabal-mode-map)
    "C-c C-j" 'haskell-interactive-switch)
  (nmap '(haskell-mode-map haskell-interactive-mode-map)
    "C-c c v" 'haskell-cabal-visit-file
    "C-c c b" 'haskell-process-cabal-build
    "C-c c r" 'haskell-process-cabal)
  (nmap 'haskell-compilation-mode-map
    "C-k" 'windmove-up ;; bind it back
    "M-k" 'compilation-previous-error
    "M-j" 'compilation-next-error)
  (nmap 'haskell-mode-map
    "C-c T" 'my/haskell-mode/toggle-process-type
    "C-c b" 'my/haskell-mode/toggle-build-command
    "C-c H" 'haskell-hayoo
    "C-c C-m" 'haskell-auto-insert-module-template
    "C-c ." 'haskell-hide-toggle
    "C-c C-o" 'haskell-process-load-file
    "C-c C-SPC" 'haskell-interactive-copy-to-prompt
    "C-c C-f" 'haskell-mode-stylish-buffer
    "C-c C-t" 'haskell-process-do-type
    "C-c C-i" 'haskell-process-do-info
    ;; Hit it repeatedly to jump between groups of imports
    "C-c C-u" 'haskell-navigate-imports)
  (require 'haskell-interactive-mode)
  (unbind-key "C-j" haskell-interactive-mode-map)
  (nmap 'haskell-interactive-mode-map
    "C-c C-j" 'haskell-interactive-switch-back)
  (imap 'haskell-interactive-mode-map
    "C-c C-l" 'haskell-interactive-mode-clear)
  :delight "hs")

(setq
 auto-mode-alist
 (remove
  (rassoc 'literate-haskell-mode auto-mode-alist)
  auto-mode-alist))

(add-to-list 'auto-mode-alist '("\\.lhs$" . latex-mode))

(use-package happy-mode
  :after (mmm-mode)
  :quelpa (happy-mode :fetcher github :repo "sergv/happy-mode"))

(use-package ormolu
  :quelpa
  (ormolu
   :fetcher github
   :repo "vyorkin/ormolu.el")
  :custom
  (ormolu-reformat-buffer-on-save nil)
  :config
  (nmap 'haskell-mode-map
    "C-c r" 'ormolu-format-buffer))

(use-package company-cabal
 :after (haskell-mode company)
 :config
 (add-to-list 'company-backends 'company-cabal))

(use-package hasky-stack
 :after (general haskell-mode)
 :config
 (nmap 'haskell-mode-map
   :prefix my/leader
   "h s" 'hasky-stack-execute
   "h n" 'hasky-stack-new))

(use-package hasky-extensions
 :after (general haskell-mode)
 :config
 (nmap 'haskell-mode-map
   :prefix my/leader
   "h e" 'hasky-extensions
   "h d" 'hasky-extensions-browse-docs))

(use-package purescript-mode
 :after (general files)
 :if (executable-find "purs")
 :preface
 (defun my/purescript-emmet ()
   (interactive)
   (let ((start (point))
         (end (save-excursion (beginning-of-line-text) (point))))
     (call-process-region start end "purescript-emmet" t t)))
 :config
 ;; Not needed when installing from melpa
 ;; (require 'purescript-mode-autoloads)
 (imap 'purescript-mode-map
   "C-c C-e" 'my/purescript-emmet))

(use-package psc-ide
 :after (general purescript-mode)
 :quelpa
 (psc-ide
   :repo "purescript-emacs/psc-ide-emacs"
   :commit "230101a3d56c9e062c3ce2bf9a4dc077e5607cc0"
   :fetcher github)
 :commands (psc-ide-mode)
 :preface
 (defun my/psc-ide/setup ()
   (setq-local evil-auto-indent nil)
   (psc-ide-mode)
   (turn-on-purescript-unicode-input-method)
   (turn-on-purescript-indentation))
 :hook
 (purescript-mode . my/psc-ide/setup)
 :init
 ;; use the psc-ide server that is
 ;; relative to npm bin directory
 (setq psc-ide-use-npm-bin t)
 :config
 (general-define-key
  :states 'normal
  :keymaps 'psc-ide-mode-map
  "C-t" 'psc-ide-goto-definition
  "C-]" 'psc-ide-goto-definition
  "g d" 'psc-ide-goto-definition)
 :delight "psc-ide")

(use-package idris-mode
  :custom
  (idris-repl-banner-functions '(idris-repl-text-banner))
  (idris-repl-prompt-style 'short)
  :config
  (idris-define-evil-keys)
  (nmap 'idris-mode-map
    "C-c C-h" 'idris-type-search
    "C-c h"   'idris-apropos
    "C-c SPC" 'idris-add-clause
    "C-c C-o" 'idris-load-file
    "C-c C-i" 'idris-info-show
    "C-c C-f" 'idris-list-holes
    "C-c C-j" 'idris-repl))

(use-package nix-mode
  :after (general)
  :mode ("\\.nix\\'" "\\.nix.in\\'")
  :config
  (nmap 'nix-mode-map
    "C-c r" 'nix-format-buffer)
  :delight "nix")

(use-package nix-drv-mode
  :ensure nix-mode
  :mode "\\.drv\\'")

(use-package nix-repl
  :ensure nix-mode
  :commands (nix-repl))

(use-package nix-update
  :config
  (nmap 'nix-mode-map
    :prefix my/leader
    "n u" 'nix-update-fetch))

(use-package company-nixos-options
  :after (company)
  :commands (company-nixos-options)
  :config
  (add-to-list 'company-backends 'company-nixos-options))

(use-package nix-sandbox)

(defvar my/opam-config/share (string-trim-right (shell-command-to-string "opam config var share")))

(use-package tuareg
  :demand t
  :mode
  (("\\.ml[ily]?$" . tuareg-mode)
   ("\\.mly$" . tuareg-menhir)
   ("\\.topml$" . tuareg-mode)
   ("\\.atd$" . tuareg-mode))
  :init
  (setq tuareg-match-patterns-aligned t)
  :hook
  (caml-mode . tuareg-mode)
  :delight "ocaml")

(with-eval-after-load 'smartparens
  (sp-local-pair 'tuareg-mode "'" nil :actions nil)
  (sp-local-pair 'tuareg-mode "`" nil :actions nil))

(use-package merlin
  :after (company tuareg)
  :demand t
  :init
  ;; Disable merlin's own error checking
  ;; We'll use flycheck-ocaml for that
  (setq
   ;; merlin-command "/run/current-system/sw/bin/ocamlmerlin"
   merlin-error-after-save nil
   merlin-completion-with-doc t)
  :config
  (add-to-list 'company-backends 'merlin-company-backend)
  (nmap 'merlin-mode-map
    "C-t" 'merlin-locate
    "C-]" 'merlin-locate
    "C-[" 'merlin-pop-stack
    "g d" 'merlin-locate)
  (nmap 'merlin-mode-map
    :prefix my/leader
    "3" 'merlin-occurrences
    "4" 'merlin-jump
    "5" 'merlin-document
    "9" 'merlin-locate-ident
    "0" 'merlin-iedit-occurrences)
  :hook
  ((tuareg-mode caml-mode) . merlin-mode))

(with-eval-after-load 'merlin-eldoc
  (custom-set-faces
   (set-face-background 'merlin-eldoc-occurrences-face "#111")))

(use-package utop
  :after (tuareg)
  :commands
  (utop-command)
  :config
  ;; (setq utop-command "opam config exec utop -- -emacs")
  (setq utop-command "opam config exec -- dune utop . -- -emacs")
  (autoload 'utop-minor-mode "utop" "Minor mode for utop" t)
  (nmap 'merlin-mode-map
    "C-c C-j" 'utop
    "C-c C-o" 'utop-eval-buffer)
  (nmap 'utop-mode-map
    "C-c C-j" 'utop
    "C-c C-SPC" 'utop-eval-phrase)
  :hook
  ((tuareg-mode reason-mode) . utop-minor-mode))

(use-package dune)

(use-package flycheck-ocaml
 :after (flycheck merlin)
 :demand t
 :commands
 (flycheck-ocaml-setup)
 :config
 ;; Enable flycheck checker
 (flycheck-ocaml-setup))

(use-package proof-general
  :custom
  (proof-delete-empty-windows t)
  ;; (proof-three-window-mode-policy 'smart)
  ;; see: https://github.com/ProofGeneral/PG/issues/404
  (proof-shrink-windows-tofit nil)
  :delight "coq")

(use-package company-coq
  :after (proof-site)
  :preface
  (defun my/company-coq/setup ()
    (interactive)
    (setq buffer-face-mode-face '(:family "JetBrains Mono"))
    (setq-local
     prettify-symbols-alist
     '((":=" . ?≜)
       ("Proof." . ?∵)
       ("Qed." . ?■)
       ("Defined." . ?□)
       ("Alpha" . ?Α) ("Beta" . ?Β) ("Gamma" . ?Γ)
       ("Delta" . ?Δ) ("Epsilon" . ?Ε) ("Zeta" . ?Ζ)
       ("Eta" . ?Η) ("Theta" . ?Θ) ("Iota" . ?Ι)
       ("Kappa" . ?Κ) ("Lambda" . ?Λ) ("Mu" . ?Μ)
       ("Nu" . ?Ν) ("Xi" . ?Ξ) ("Omicron" . ?Ο)
       ("Pi" . ?Π) ("Rho" . ?Ρ) ("Sigma" . ?Σ)
       ("Tau" . ?Τ) ("Upsilon" . ?Υ) ("Phi" . ?Φ)
       ("Chi" . ?Χ) ("Psi" . ?Ψ) ("Omega" . ?Ω)
       ("alpha" . ?α) ("beta" . ?β) ("gamma" . ?γ)
       ("delta" . ?δ) ("epsilon" . ?ε) ("zeta" . ?ζ)
       ("eta" . ?η) ("theta" . ?θ) ("iota" . ?ι)
       ("kappa" . ?κ) ("lambda" . ?λ) ("mu" . ?μ)
       ("nu" . ?ν) ("xi" . ?ξ) ("omicron" . ?ο)
       ("pi" . ?π) ("rho" . ?ρ) ("sigma" . ?σ)
       ("tau" . ?τ) ("upsilon" . ?υ) ("phi" . ?φ)
       ("chi" . ?χ) ("psi" . ?ψ) ("omega" . ?ω)))
    (sp-local-pair 'coq-mode "'" nil :actions nil))
  :commands (company-coq-mode)
  :hook
  (coq-mode . company-coq-mode)
  (coq-mode . my/company-coq/setup)
  :init
  (setq
   ;; Enable autocompletion for theorem names and
   ;; symbols defined in the libraries we load
   company-coq-live-on-the-edge t
   company-coq-disabled-features '()
  ;; Disable symbol prettification
   company-coq-disabled-features '(prettify-symbols)
   company-coq-dynamic-autocompletion t)
  :config
  (nmap 'coq-mode-map
    "C-C C-t" 'coq-About)
  (nmap 'coq-mode-map
    :prefix my/leader
    "3" 'coq-SearchAbout
    "4" 'coq-Print
    "5" 'coq-LocateNotation
    "6" 'coq-LocateConstant
    "7" 'coq-Inspect
    "8" 'coq-About
    "9" 'coq-Show
    "0" 'coq-Check)
  (nmap 'coq-mode-map
    "g d" 'company-coq-jump-to-definition))

(use-package tla-mode
  :quelpa
  (tla-mode :fetcher github :repo "ratish-punnoose/tla-mode")
  :mode "\.tla$")

(use-package sml-mode
  :quelpa (sml-mode :fetcher github :repo "emacsmirror/sml-mode")
  :mode "\\.sml$"
  :custom
  (sml-indent-level 2)
  :config
  (nmap 'sml-mode-map
    "C-c C-o" 'sml-prog-proc-load-file
    "C-c C-j" 'sml-prog-proc-switch-to))

(use-package geiser
 :after general)

(use-package scheme
 :ensure nil
 :after (geiser)
 :preface
 (defun my/scheme/setup ()
   (geiser-mode t))
 :hook
 (scheme-mode . my/scheme/setup))

(use-package quack
 :after (scheme)
 :config
 (setq
  ;; use emacs-style fontification
  quack-fontify-style 'emacs))

(use-package faceup)
(use-package racket-mode
 :after
 (general
  smartparens
  org
  faceup
  geiser)
 :if (executable-find "racket")
 :mode ("\\.rkt[dl]?\\'" . racket-mode)
 :interpreter ("racket" . racket-mode)
 :hook
 (racket-mode . smartparens-mode)
 :init
 (setq
  geiser-scheme-implementation 'racket
  racket-smart-open-bracket-enable t)
 :config
 (add-to-list 'org-babel-load-languages '(racket . t))
 (sp-local-pair 'racket-mode "'" nil :actions nil)
 (sp-local-pair 'racket-mode "`" nil :actions nil))

(use-package clojure-mode
 :after (general company org)
 :defer 1
 :commands
 (define-clojure-indent
  put-clojure-indent)
 :mode
 (("\\.clj\\'" . clojure-mode)
  ("\\.edn\\'" . clojure-mode)
  ("\\.boot\\'" . clojure-mode)
  ("\\.cljs.*\\'" . clojure-mode))
 :init
 (setq inferior-lisp-program "lein repl")
 :config
 (add-to-list 'org-babel-load-languages '(clojure . t))
 (nmap 'clojure-mode-map
   :prefix my/leader
   "C s" 'cider-start-http-server
   "C r" 'cider-refresh
   "C u" 'cider-user-ns
   "C R" 'cider-restart)
 (define-clojure-indent (fact 1))
 (define-clojure-indent (facts 1)))

(use-package clojure-mode-extra-font-locking
 :after (clojure-mode)
 :defer 1
 :init
 (font-lock-add-keywords
  nil
  '(("(\\(facts?\\)"
     (1 font-lock-keyword-face))
    ("(\\(background?\\)"
     (1 font-lock-keyword-face)))))

(use-package cider
 :after (clojure-mode)
 :defer 1
 :commands (cider-mode)
 :custom
 (cider-repl-result-prefix ";; => ")
 :init
 (setq
  ;; go right to the REPL buffer when it's finished connecting
  cider-repl-pop-to-buffer-on-connect t
  ;; when there's a cider error, show its buffer and switch to it
  cider-show-error-buffer t
  cider-auto-select-error-buffer t
  cider-repl-history-file "~/.emacs.d/cider-history"
  cider-repl-wrap-history t)
 :hook
 (clojure-mode . clojure-mode))

(use-package kibit-helper
 :defer 1)

(use-package flycheck-clojure
  :after (flycheck clojure-mode)
  :defer 1
  :commands
  (flycheck-clojure-setup)
  :config
  (eval-after-load 'flycheck '(flycheck-clojure-setup)))

(use-package scala-mode
 :after (general)
 :if (executable-find "scala")
 :interpreter
 ("scala" . scala-mode)
 :hook
  (scala-mode . lsp))

(use-package sbt-mode
  :commands sbt-start sbt-command
  :config
  ;; WORKAROUND: https://github.com/ensime/emacs-sbt-mode/issues/31
  ;; allows using SPACE when in the minibuffer
  (substitute-key-definition
   'minibuffer-complete-word
   'self-insert-command
   minibuffer-local-completion-map)
   ;; sbt-supershell kills sbt-mode:  https://github.com/hvesalai/emacs-sbt-mode/issues/152
   (setq sbt:program-options '("-Dsbt.supershell=false"))
)

(use-package lsp-metals
  :config (setq lsp-metals-treeview-show-when-views-received t))

(use-package kotlin-mode)

(use-package flycheck-kotlin
 :after (kotlin-mode flycheck)
 :commands
 (flycheck-kotlin-setup)
 :config
 (flycheck-kotlin-setup))

(use-package rustic
 :preface
 (defun my/rustic/setup ()
  ;; So that run C-c C-c C-r works without having to confirm,
  ;; but don't try to save rust buffers that are not file visiting.
  ;; Once https://github.com/brotzeit/rustic/issues/253 has been
  ;; resolved this should no longer be necessary
  (when buffer-file-name
    (setq-local buffer-save-without-query t)))
 :config
 (setq rustic-format-on-save t)
 (nmap 'rustic-mode-map
   "C-c R" 'rustic-cargo-fmt
   "C-c r" 'rustic-format-buffer)
 :hook
 (rustic-mode . my/rustic/setup))

(use-package prolog
 :ensure nil
 :preface
 (defun my/mercury-mode/setup ()
   (electric-indent-mode -1))
 :commands
 (prolog-mode mercury-mode)
 :hook
 (mercury-mode . my/mercury-mode/setup)
 :mode
 (("\\.pl\\'" . prolog-mode)
  ("\\.m\\'" . mercury-mode))
 :init
 (setq prolog-system 'swi))

(use-package dhall-mode
 :custom
 (dhall-format-at-save t)
 :mode "\\.dhall\\'")

 (use-package terraform-mode
  :hook (terraform-mode . terraform-format-on-save-mode))

 (use-package company-terraform
  :after (terraform company)
  :commands
  (company-terraform-init)
  :config
  (company-terraform-init))

(use-package format-sql
 :after (general)
 :config
 (vmap 'sql-mode-map
   "C-c R" 'format-sql-region)
 (nmap 'sql-mode-map
   "C-c r" 'format-sql-buffer))

(use-package sqlup-mode
  :after (general)
  :hook
  ;; capitalize keywords in SQL mode
  ;; capitalize keywords in an interactive session (e.g. psql)
  ((sql-mode sql-interactive-mode) . sqlup-mode)
  :config
  (add-to-list 'sqlup-blacklist "name")
  (add-to-list 'sqlup-blacklist "public")
  (add-to-list 'sqlup-blacklist "state")
  (nmap
    :keymaps '(sql-mode-map sql-interactive-mode-map)
    :prefix my/leader
    "S u" 'sqlup-capitalize-keywords-in-region
    "S U" 'sqlup-capitalize-keywords-in-buffer))

(use-package json-mode
  :mode "\\.bowerrc$")

(use-package json-reformat)

(use-package yaml-mode
 :config
 :delight "yaml")

(use-package flycheck-yamllint
 :after (flycheck yaml-mode)
 :commands
 (flycheck-yamllint-setup)
 :config
 (flycheck-yamllint-setup))

(use-package toml-mode)

(use-package protobuf-mode)

(use-package emmet-mode
 :after (general sgml-mode)
 :defer 1
 :commands
 emmet-mode
 :hook
 ((sgml-mode ; auto-start on any markup modes
   css-mode  ; enable css abbreviation
   html-mode
   jade-mode) . emmet-mode)
 :config
 (imap
   "C-x C-o" 'emmet-expand-line)
 :delight "emmet")

(use-package python-mode
 :preface
 (defun my/python-mode/setup ()
   (mapc (lambda (pair) (push pair prettify-symbols-alist))
         '(("def" . "𝒇")
           ("class" . "𝑪")
           ("and" . "∧")
           ("or" . "∨")
           ("not" . "￢")
           ("in" . "∈")
           ("not in" . "∉")
           ("return" . "⟼")
           ("yield" . "⟻")
           ("for" . "∀")
           ("!=" . "≠")
           ("==" . "＝")
           (">=" . "≥")
           ("<=" . "≤")
           ("[]" . "⃞")
           ("=" . "≝"))))
 :hook
 (python-mode . my/python-mode/setup))

(use-package inf-ruby
 :hook
 ;; automatically switch from common ruby compilation modes
 ;; to interact with a debugger
 (compilation-filter . inf-ruby-auto-enter)
 ;; required to use binding.pry or byebug
 (after-init . inf-ruby-switch-setup))

(use-package robe
 :after (company)
 :hook
 (ruby-mode . robe-mode)
 :config
 (add-to-list 'company-backends 'company-robe)
 :delight "robe")

(use-package rubocop
 :after (robe)
 :hook
 (ruby-mode . rubocop-mode)
 :delight "rcop")

(use-package bundler
 :after general
 :config
 (nmap 'ruby-mode-map
   :prefix my/leader
   "b i" 'bundle-install
   "b c" 'bundle-console
   "b o" 'bundle-outdated
   "b u" 'bundle-update
   "b e" 'bundle-exec))

(use-package rbenv
 :commands
 (global-rbenv-mode)
 :preface
 (defun my/rbenv/modeline (current-ruby)
   (append
    '(" ruby [")
    (list (propertize current-ruby 'face 'rbenv-active-ruby-face))
    '("]")))
 :hook
 (ruby-mode . rbenv-use-corresponding)
 :init
 (setq rbenv-modeline-function 'my/rbenv/modeline)
 :config
 (global-rbenv-mode)
 (nmap 'ruby-mode-map
   :prefix "C-c R"
   "c" 'rbenv-use-corresponding
   "u" 'rbenv-use))

(use-package rake
 :after (general projectile)
 :init
 (setq rake-completion-system projectile-completion-system)
 :config
 (nmap 'ruby-mode-map
   :prefix my/leader
   "r" 'rake))

(use-package rspec-mode)

(use-package projectile-rails
 :after projectile
 :commands
 (projectile-rails-global-mode)
 :init
 (setq
  projectile-rails-vanilla-command "bin/rails"
  projectile-rails-spring-command "bin/spring"
  projectile-rails-zeus-command "bin/zeus")
 :config
 (projectile-rails-global-mode)
 :diminish)

(use-package php-mode
  :mode "\\.\\(php\\|inc\\)$")

(use-package gradle-mode
  :hook ((java-mode kotlin-mode) . gradle-mode))

(use-package javadoc-lookup)

(use-package web-mode
  :after (tide)
  :preface
  (defun my/web-mode/setup ()
    (interactive)
    (when (string-equal "tsx" (file-name-extension buffer-file-name))
      (setup-tide-mode)))
  :mode
  (("\\.html?\\'" . web-mode)
   ("\\.html\\.erb\\'" . web-mode)
   ("\\.erb\\'" . web-mode)
   ("\\.djhtml\\'" . web-mode)
   ("\\.tsx\\'" . web-mode)
   ("\\.jsx\\'" . web-mode)
   ("\\.mustache\\'" . web-mode)
   ("\\.jinja\\'" . web-mode)

   ("\\.css\\'" . web-mode)
   ("\\.scss\\'" . web-mode)

   ("\\.[agj]sp\\'" . web-mode)
   ("\\.as[cp]x\\'" . web-mode)
   ("\\.as\\'" . web-mode)

   ("\\.phtml\\'" . web-mode)
   ("\\.tpl\\.php\\'" . web-mode)
   ("\\.php\\'" . web-mode))

  :init
  (setq
   ;; indent HTML automatically
   web-mode-indent-style 2
   ;; offsets
   web-mode-markup-indent-offset 2
   web-mode-css-indent-offset 2
   web-mode-code-indent-offset 2

   web-mode-engines-alist
   '(("\\.jinja\\'"  . "django")
     ("php" . "\\.php[3-5]?"))

   web-mode-enable-auto-pairing t
   web-mode-enable-css-colorization t
   web-mode-enable-current-element-highlight t
   web-mode-enable-current-column-highlight nil)
  :config
  (flycheck-add-mode 'javascript-eslint 'web-mode)
  :hook
  (web-mode . my/web-mode/setup))

(use-package cakecrumbs
  :config
  (cakecrumbs-auto-setup))

(use-package company-web
 :after company
 :demand t)

(use-package css-mode)

(use-package counsel-css
  :after counsel
)

(use-package scss-mode
 :config
 :delight "scss")

(use-package go-mode
  :after (company flycheck)
  :if (executable-find "go")
  :preface
  (defun my/go-mode/setup ()
    (add-hook 'before-save-hook 'gofmt-before-save)
    (add-hook 'go-mode-hook 'flycheck-mode)
    (setq-default)
    (setq standard-indent 8)
    (setq tab-width 8)
    (setq indent-tabs-mode 1))
  :mode "\\.go\\'"
  :hook
  (go-mode . my/go-mode/setup))

(use-package company-go
 :after (company go-mode)
 :hook
 (go-mode . company-mode)
 :config
 (add-to-list 'company-backends 'company-go))

(use-package go-stacktracer)

(use-package go-add-tags)

(use-package go-eldoc
  :hook
  (go-mode . go-eldoc-setup))

(use-package go-gopath)

(use-package go-direx)

(use-package gotest)

(use-package go-playground)

(use-package typescript-mode
  :preface
  (defun my/typescript-mode/setup ()
    ;; The error messages produced by tsc when its pretty flag
    ;; is turned on include ANSI color escapes, which by default
    ;; compilation-mode does not interpret. In order to get the
    ;; escapes parsed we do the following:
    (require 'ansi-color)
    (defun colorize-compilation-buffer ()
      (ansi-color-apply-on-region compilation-filter-start (point-max)))
    (add-hook 'compilation-filter-hook 'colorize-compilation-buffer))
  :custom
  (typescript-indent-level 2)
  :hook
  (typescript-mode . my/typescript-mode/setup))

(use-package tide
  :after (typescript-mode flycheck company)
  :preface
  (defun my/tide/setup ()
    (interactive)
    (tide-setup)
    (flycheck-mode +1)
    (eldoc-mode +1)
    (tide-hl-identifier-mode +1)
    (company-mode +1))
  :custom
  (tide-format-options
   '(:indentSize 2 :tabSize 2 :indentStyle 2))
  :config
  (flycheck-add-next-checker 'javascript-eslint 'jsx-tide 'append)
  (nmap tide-mode-map
    :prefix my/leader
    "0" 'tide-jsdoc-template)
  :hook
  ((typescript-mode . my/tide/setup)
   (before-save . tide-format-before-save)))

(use-package ts-comint
  :custom
  (ts-comint-program-command "ts-node"))

(use-package tern
 :commands
 (tern-mode)
 :config
 ;; Enable js completion between <script>...</script> etc
 (defadvice company-tern (before web-mode-set-up-ac-sources activate)
   "Set `tern-mode' based on current language before running company-tern."
   (message "advice")
   (if (equal major-mode 'web-mode)
       (let ((web-mode-cur-language (web-mode-language-at-pos)))
         (if (or (string= web-mode-cur-language "javascript")
                 (string= web-mode-cur-language "jsx"))
             (unless tern-mode (tern-mode))
           (if tern-mode (tern-mode -1)))))))

(use-package npm-mode
 :commands
 (npm-mode npm-global-mode)
 :config
 (npm-global-mode)
 :diminish npm-mode)

(use-package js2-mode
 :init
 ;; indent step is 2 spaces
 (setq-default js2-basic-offset 2)
 (setq-default js-indent-level 2)
 (setq
  ;; configure indentation
  js2-enter-indents-newline t
  js2-auto-indent-p t
  ;; Idle timeout before reparsing buffer
  js2-idle-timer-delay 0.5
  ;; disable error parsing in favor of Flycheck
  js2-strict-missing-semi-warning nil)
 :commands js2-mode
 :config
 (add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))
 :delight "js2")

(use-package eslintd-fix
 :hook
 (tide-mode . eslintd-fix-mode))

(use-package xref-js2
 :preface
 (defun my/xref-js2/add-backend ()
   (add-hook 'xref-backend-functions
             'xref-js2-xref-backend nil t))
 :hook
 (js2-mode . my/xref-js2/add-backend)
 :config
 (unbind-key "M-." js2-mode-map))

(use-package js2-refactor
 :commands
(js2r-add-keybindings-with-prefix)
 :hook
 (js2-mode . js2-refactor-mode)
 :config
 ;; enable minor mode for js refactoring
 ;; see: https://github.com/magnars/js2-refactor.el#refactorings
 (js2r-add-keybindings-with-prefix "C-c C-j"))

(use-package prettier-js
 :hook
 ((js2-mode-hook web-mode-hook) . prettier-js-mode)
 :delight "pr")

(use-package graphql-mode
 :mode "\\.graphql\\'"
 :custom
 (graphql-url "http://localhost:8000/api/graphql/query"))

(use-package vue-mode)

(use-package elm-mode
  :custom
  (elm-format-on-save t)
  (elm-package-json "elm.json")
  (elm-tags-exclude-elm-stuff nil)
  (elm-tags-on-save t))

(use-package flycheck-elm
 :after (elm-mode flycheck)
 :hook
 (flycheck-mode . flycheck-elm-setup))

(use-package nginx-mode)

(use-package d-mode)

(use-package modern-cpp-font-lock
  :config
  (modern-c++-font-lock-global-mode t))

(use-package glsl-mode)

(use-package company-glsl)

(use-package solidity-mode)

(use-package solidity-flycheck
 :custom
 (solidity-solc-path "~/.npm-packages/bin/solcjs")
 (solidity-solium-path "~/.npm-packages/bin/solium")
 (solidity-flycheck-solc-checker-active nil)
 (solidity-flycheck-solium-checker-active nil))

(use-package kconfig-mode)

(use-package octave
 :after general
 :ensure nil
 ;; Overlaps with mercury-mode
 :mode ("\\.octave\\'" . octave-mode))

(use-package cmake-mode
  :mode (("\\.cmake\\'" . cmake-mode)
         ("\\CMakeLists.txt$" . cmake-mode)))

(use-package cmake-font-lock
  :config
  (autoload 'cmake-font-lock-activate "cmake-font-lock" nil t)
  (add-hook 'cmake-mode-hook 'cmake-font-lock-activate))

(use-package eldoc-cmake
  :hook (cmake-mode . eldoc-cmake-enable))

(use-package tex
 :demand t
 :ensure auctex
 :config
 (setq-default TeX-engine 'luatex)
 (setq-default TeX-PDF-mode t)
 (setq-default TeX-master nil)
 (setq TeX-view-program-selection '((output-pdf "PDF Tools")))
 (setq reftex-plug-into-AUCTeX t)
 (setq reftex-bibliography-commands '("bibliography" "nobibliography" "addbibresource"))
 (setq reftex-use-external-file-finders t)
 (setq reftex-external-file-finders
       '(("tex" . "kpsewhich -format=.tex %f")
         ("bib" . "kpsewhich -format=.bib %f")))
 (setq reftex-insert-label-flags '("s" "sft" "e"))
 (setq TeX-electric-sub-and-superscrip t)
 (setq TeX-electric-math (cons "\\(" "\\)"))
 :hook
 ((LaTeX-mode . visual-line-mode)
  (LaTeX-mode . turn-on-auto-fill)
  (LaTeX-mode . flyspell-mode)
  (LaTeX-mode . LaTeX-math-mode)
  (LaTeX-mode . turn-on-reftex)
  (TeX-after-compilation-finished-functions
    . TeX-revert-document-buffer)))

(use-package auctex-latexmk
  :hook (LaTeX-mode . auctex-latexmk-setup))

(use-package company-math
 :config
 (add-to-list 'company-backends 'company-math-symbols-latex)
 (add-to-list 'company-backends 'company-math-symbols-unicode))

(use-package pug-mode)

(use-package jade-mode)

(use-package haml-mode)

(use-package slim-mode
 :delight "slim")

(use-package lua-mode
  :preface
  (defun my/lua-prettify-symbols-setup ()
    (dolist (symbol '(("~="  . (?\s (Br . Bl) ?\s (Bc . Bc) ?≠))
                      ("function"  . ?ƒ)
                      ("math.huge" . ?∞)))
      (cl-pushnew symbol prettify-symbols-alist :test #'equal)))
  :mode "\\.lua\\'"
  :custom
  (lua-documentation-function 'eww)
  :init
  (setq lua-indent-level 2)
  :hook
  (lua-mode . my/lua-prettify-symbols-setup))

(use-package lua-block
  :after (lua-mode)
  :quelpa
  (lua-block
   :fetcher url
   :url "http://www.emacswiki.org/emacs/download/lua-block.el")
  :init
  (autoload 'lua-block-mode "lua-block" nil t)
  :delight "lb")

(use-package forth-mode)

(use-package arduino-mode
  :init
  ;; TODO: irony-arduino-includes-options
  ;; see https://github.com/yuutayamada/company-arduino/issues/5
  ;; TODO: https://github.com/yuutayamada/company-arduino/issues/6
  :config
  ;; Activate irony-mode on arduino-mode
  (add-hook 'arduino-mode-hook 'irony-mode)
  (nmap
    :prefix my/leader
    "a v" 'arduino-verify
    "a u" 'arduino-upload
    "a i" 'arduino-install-library
    "a m" 'arduino-menu
    "a n" 'arduino-sketch-new
    "a b" 'arduino-install-boards
    "a s" 'arduino-serial-monitor))

(use-package company-arduino
  :after (irony company company-irony company-c-headers)
  :config
  ;; Add arduino's include options to irony-mode's variable
  (add-hook 'irony-mode-hook 'company-arduino-turn-on)
  ;; Configuration for company-c-headers.el
  ;; The `company-arduino-append-include-dirs' function appends
  ;; Arduino's include directories to the default directories
  ;; if `default-directory' is inside `company-arduino-home'. Otherwise
  ;; just returns the default directories.
  ;; Please change the default include directories accordingly.
  (defun my-company-c-headers-get-system-path ()
    "Return the system include path for the current buffer."
    (let ((default '("/usr/include/" "/usr/local/include/")))
      (company-arduino-append-include-dirs default t)))
  (setq company-c-headers-path-system 'my-company-c-headers-get-system-path))

(use-package robots-txt-mode)

(use-package dotenv-mode
 :config
 (add-to-list 'auto-mode-alist '("\\.env\\..*\\'" . dotenv-mode)))

(use-package csv-mode
  :mode "\\.[Cc][Ss][Vv]$"
  :init
  (setq
   ;; default separators for CSV files.
   csv-separators '("," ";" "|" " " "\t")
   ;; number of lines to consider part of header.
   csv-header-lines 1))

(use-package apib-mode
  :after general
  :config
  (nmap 'apib-mode-map
    :prefix my/leader
    "z p" 'apib-parse           ; Parse the API Blueprint
    "z v" 'apib-validate        ; Validate the API Blueprint
    "z j" 'apib-get-json        ; Print all generated JSON bodies
    "z s" 'apib-get-json-schema ; Print all generated JSON Schemas
    ))

(use-package nasm-mode)

(use-package iasm-mode)

(use-package bnf-mode
 :mode "\\.bnf\\'")

(use-package cuda-mode
  :mode
  (("\\.cu\\'" . cuda-mode)
   ("\\.cuh\\'" . cuda-mode)))

(use-package gnu-apl-mode)
(use-package dyalog-mode)

(use-package ansible)

(use-package dap-mode
  :hook
  (lsp-mode . dap-mode)
  (lsp-mode . dap-ui-mode)
  :config
  (require 'dap-cpptools)
  (dap-mode 1)
  (dap-ui-mode 1)
  (add-hook 'dap-stopped-hook
    (lambda (arg) (call-interactively #'dap-hydra))))

(use-package gdb-mi
  :ensure nil
  :commands (gdb-many-windows)
  :hook
  (gdb . gdb-many-windows))

(use-package coverlay
  :preface
  (defun my/coverlay-mode-enable ()
    "Turn on `coverlay-mode'."
    (coverlay-minor-mode 1)
    (when (and (buffer-file-name) (not (bound-and-true-p coverlay--loaded-filepath)))
      (let* ((coverage-file
              (concat
               (locate-dominating-file (file-name-directory (buffer-file-name)) "coverage")
               "coverage"
               "/lcov.info")))
        (when (file-exists-p coverage-file)
          (coverlay-watch-file coverage-file)))))
  :custom
  (coverlay:mark-tested-lines nil)
  :diminish coverlay-minor-mode)

(use-package quickrun
  :preface
  (defun my/display-ctrl-M-as-newline ()
    "Display `^M' as newline."
    (interactive)
    (setq buffer-display-table (make-display-table))
    (aset buffer-display-table ?\^M [?\n]))
  :hook
  (quickrun--mode . my/display-ctrl-M-as-newline)
  :config
  (nmap
    :prefix my/leader
    "i q" 'quickrun
    "i r" 'quickrun-region
    "i a" 'quickrun-autorun-mode))

(use-package docker
 :diminish docker-mode
 :config
 (nmap
   :prefix my/leader
   "d" 'docker))

(use-package docker-compose-mode)

(use-package timonier
 :after general
 :init
 (setq timonier-k8s-proxy "http://localhost:8001"))

(use-package restclient
 :mode
 ("\\.http\\'" . restclient-mode))

(use-package restclient-test
 :hook
 (restclient-mode-hook . restclient-test-mode))

(use-package ob-restclient
 :after (org restclient)
 :init
 (org-babel-do-load-languages
  'org-babel-load-languages
  '((restclient . t))))

(use-package company-restclient
 :after (company restclient)
 :custom-update
 (company-backends '(company-restclient)))

(use-package sloc
  :quelpa (sloc :fetcher github :repo "leoliu/sloc.el"))

(use-package hydra
 :config

(defhydra hydra-zoom ()
  "
 ^Zoom^
───────────────────────────────────
"
  ("=" text-scale-increase nil)
  ("k" text-scale-increase "in")
  ("j" text-scale-decrease "out")
  ("+" text-scale-increase "in")
  ("-" text-scale-decrease "out")
  ("0" (text-scale-set 0) "remove"))

(defhydra hydra-window ()
  "
Movement^^      ^Split^            ^Resize^
────────────────────────────────────────────────────
_h_ ←          _v_ertical          _H_ X←
_j_ ↓          _s_ horizontal      _J_ X↓
_k_ ↑          _U_ undo            _K_ X↑
_l_ →          _R_ reset           _L_ X→
_f_ollow       _d_lt Other
_SPC_ cancel   _o_nly this
"
  ("h" windmove-left)
  ("j" windmove-down)
  ("k" windmove-up)
  ("l" windmove-right)

  ("H" evil-window-increase-width)
  ("J" evil-window-increase-height)
  ("K" evil-window-decrease-height)
  ("L" evil-window-decrease-width)

  ("f" follow-mode)
  ("v"
   (lambda ()
     (interactive)
     (split-window-right)
     (windmove-right))
   )
  ("s"
   (lambda ()
     (interactive)
     (split-window-below)
     (windmove-down))
   )
  ("d" delete-window)
  ("o" delete-other-windows)
  ("i" ace-maximize-window)
  ("U"
   (progn
     (winner-undo)
     (setq this-command 'winner-undo))
   )
  ("R" winner-redo)
  ("SPC" nil))

(defhydra hydra-rectangle ()
  "
^Rectangle^
───────────────────
_m_: mark region
_k_: kill region
_y_: yank region
  "
  ("m" rectangle-mark-mode nil)
  ("y" yank-rectangle nil)
  ("k" kill-rectangle nil)

  ("l" forward-char)
  ("h" backward-char)
  ("j" next-line)
  ("k" previous-line)
  ("0" move-beginning-of-line)
  ("$" move-end-of-line))

(defhydra hydra-flycheck (:color blue)
  "
  ^
  ^Flycheck^          ^Errors^            ^Checker^
  ^────────^──────────^──────^────────────^───────^─────
  _M_ manual          _<_ previous        _?_ describe
  _v_ verify setup    _>_ next            _d_ disable
  ^^                  _f_ check           _m_ mode
  ^^                  _l_ list            _s_ select
  ^^                  ^^                  ^^
  "
  ("<" flycheck-previous-error :color pink)
  (">" flycheck-next-error :color pink)
  ("?" flycheck-describe-checker)
  ("M" flycheck-manual)
  ("d" flycheck-disable-checker)
  ("f" flycheck-buffer)
  ("l" flycheck-list-errors)
  ("m" flycheck-mode)
  ("s" flycheck-select-checker)
  ("v" flycheck-verify-setup))

(defhydra hydra-yasnippet (:color blue :hint nil)
  "
^YASnippets^
───────────────────────
_i_: insert snippet
_v_: visit snippet files
_n_: new
_r_: reload all
  "
  ("i" yas-insert-snippet)
  ("v" yas-visit-snippet-file :color blue)
  ("n" yas-new-snippet)
  ("r" yas-reload-all))

(defhydra hydra-macro ()
  "
^Macro^
────────────────────────────
_j_: create new macro
_k_: end creation of new macro
_e_: execute last macro
_n_: insert Counter
  "
  ("j" kmacro-start-macro :color blue)
  ("k" kmacro-end-macro :colocr blue)
  ("e" kmacro-end-or-call-macro-repeat)
  ("n" kmacro-insert-counter))

(defhydra hydra-org/base ()
  "
^Org base^
───────────────
_s_: store link
_l_: insert link

_r_: refile
_t_: insert tag
"
  ("s" org-store-link nil :color blue)
  ("l" org-insert-link nil :color blue)
  ("r" org-refile nil :color blue)
  ("t" org-set-tags-command nil :color blue))

(defhydra hydra-org/link ()
  "
^Org link^
────────────────────────────────────────────────────────
_i_ backward slurp     _o_ forward slurp    _n_ next link
_j_ backward barf      _k_ forward barf     _p_ previous link
"
  ("i" org-link-edit-backward-slurp)
  ("o" org-link-edit-forward-slurp)
  ("j" org-link-edit-backward-barf)
  ("k" org-link-edit-forward-barf)
  ("n" org-next-link)
  ("p" org-previous-link))

(defhydra hydra-org/table ()
  "
^Org table^
──────────────────────────────────────────────────────────
_r_ recalculate     _w_ wrap region      _c_ toggle coordinates
_i_ iterate table   _t_ transpose        _D_ toggle debugger
_B_ iterate buffer  _E_ export table     _d_ edit field
_e_ eval formula    _s_ sort lines       ^^
"
  ("E" org-table-export :color blue)
  ("s" org-table-sort-lines)
  ("d" org-table-edit-field)
  ("e" org-table-eval-formula)
  ("r" org-table-recalculate)
  ("i" org-table-iterate)
  ("B" org-table-iterate-buffer-tables)
  ("w" org-table-wrap-region)
  ("D" org-table-toggle-formula-debugger)
  ("t" org-table-transpose-table-at-point)
  ("c" org-table-toggle-coordinate-overlays :color blue))

(defhydra hydra-org/babel ()
  "
^Org babel^
────────────────────────────────────────────────
_n_ next       _i_ info           _I_ insert header
_p_ prev       _c_ check          _e_ examplify region
_h_ goto head  _E_ expand         ^^
^^             _s_ split          ^^
^^             _r_ remove result  ^^
"
  ("i" org-babel-view-src-block-info)
  ("I" org-babel-insert-header-arg)
  ("c" org-babel-check-src-block :color blue)
  ("s" org-babel-demarcate-block :color blue)
  ("n" org-babel-next-src-block)
  ("p" org-babel-previous-src-block)
  ("E" org-babel-expand-src-block :color blue)
  ("e" org-babel-examplify-region :color blue)
  ("r" org-babel-remove-result :color blue)
  ("h" org-babel-goto-src-block-head))

(defhydra hydra-help ()
  "
^Help^
────────────────────────────
_f_: callable
_F_: function
_v_: variable
_c_: command
_k_: key
_m_: mode
_l_: view lossage
_M_: view messages
"
  ("M" view-echo-area-messages :color blue)
  ("f" helpful-callable :color blue)
  ("F" helpful-function :color blue)
  ("v" helpful-variable :color blue)
  ("c" helpful-command :color blue)
  ("k" helpful-key :color blue)
  ("m" describe-mode :color blue)
  ("l" view-lossage :color blue))

(defhydra hydra-packages ()
  "
^Packages^
─────────────────
_l_: list
_r_: refresh
_d_: delete
_e_: describe
_i_: install
_f_: install file
"
  ("l" package-list-packages)
  ("r" package-refresh-contents)
  ("d" package-delete)
  ("i" package-install)
  ("f" package-install-file)
  ("e" describe-package))

(defhydra hydra-search-online ()
  "
  ^
^Search Online^
────────────────────────────────────────────────────────
_g_: google         _y_: youtube           _t_: twitter
_t_: translate      _u_: urban dictionary  _m_: melpa
_w_: wikipedia      _h_: hoogle            _M_: google maps
_s_: stack overflow _H_: hackage           _i_: google images
_G_: github         _p_: pursuit           _d_: duckduckgo
  "
  ("g" engine/search-google)
  ("t" engine/search-google-translate)
  ("w" engine/search-wikipedia)
  ("s" engine/search-stack-overflow)
  ("G" engine/search-github)
  ("y" engine/search-youtube)
  ("u" engine/search-urban-dictionary)
  ("h" engine/search-hoogle)
  ("H" engine/search-hackage)
  ("p" engine/search-pursuit)
  ("m" engine/search-melpa)
  ("T" engine/search-twitter)
  ("M" engine/search-google-maps)
  ("i" engine/search-google-images)
  ("d" engine/search-duckduckgo))

(nmap
  :prefix my/leader+
  "f" 'hydra-flycheck/body
  "h" 'hydra-help/body
  "o o" 'hydra-org/base/body
  "o l" 'hydra-org/link/body
  "o t" 'hydra-org/table/body
  "o b" 'hydra-org/babel/body
  "r" 'hydra-rectangle/body
  "m" 'hydra-macro/body
  "p" 'hydra-packages/body
  "C-SPC" 'hydra-search-online/body
  "S" 'hydra-yasnippet/body
  "t" 'hydra-zoom/body
  "w" 'hydra-window/body))

(use-package calfw-org)
(use-package calfw
 :demand t
 :config
 (require 'calfw-org)

 ;; Nicer Unicode characters
 (setq
   cfw:fchar-junction ?╋
   cfw:fchar-vertical-line ?┃
   cfw:fchar-horizontal-line ?━
   cfw:fchar-left-junction ?┣
   cfw:fchar-right-junction ?┫
   cfw:fchar-top-junction ?┯
   cfw:fchar-top-left-corner ?┏
   cfw:fchar-top-right-corner ?┓))

(use-package pdf-tools
 :mode ("\\.pdf\\'" . pdf-view-mode)
 :commands
 (pdf-tools-install)
 :config
 (pdf-tools-install)
 (setq-default pdf-view-display-size 'fit-width))

(use-package djvu)

(use-package nov
  :preface
  (defun my/nov-delayed-render-setup ()
    (run-with-idle-timer 0.2 nil 'nov-render-document))
  (defun my/nov-fringes-setup ()
    "Hide the fringes for `nov-mode'."
    (set-window-fringes (get-buffer-window) 0 0 nil))
  :mode
  ("\\.epub$" . nov-mode)
  :hook
  (nov-mode . my/nov-delayed-render-setup)
  (nov-mode . my/nov-fringes-setup))

(use-package google-translate
 :after (general)
 :demand t
 :init
 (setq google-translate-default-source-language "en")
 (setq google-translate-default-target-language "ru")
 :config
 (require 'google-translate-default-ui)
 (nmap
  :prefix "C-c"
  "t" 'google-translate-at-point
  "q" 'google-translate-query-translate))

(use-package net-utils
 :config
 (nmap
   :prefix my/leader
   "N p" 'ping
   "N i" 'ifconfig
   "N w" 'iwconfig
   "N n" 'netstat
   "N a" 'arp
   "N r" 'route
   "N h" 'nslookup-host
   "N d" 'dig
   "N s" 'smbclient))

(use-package ix
 :after general
 :config
 (nmap
   :prefix my/leader
   "G i i" 'ix
   "G i b" 'ix-browse
   "G i d" 'ix-delete))

(use-package direnv
 :demand t
 :custom
 (direnv-always-show-summary t)
 :config
 (direnv-mode))

(use-package carbon-now-sh
  :config
  (vmap 'prog-mode
    "C-c c" 'carbon-now-sh))

(use-package engine-mode
 :config
 (engine-mode t)
 (engine/set-keymap-prefix (kbd "C-SPC C-SPC"))
 (defengine amazon
   "http://www.amazon.com/s/ref=nb_sb_noss?url=search-alias%3Daps&field-keywords=%s")
 (defengine duckduckgo
   "https://duckduckgo.com/?q=%s"
   :keybinding "d")
 (defengine github
   "https://github.com/search?q=%s&type=Code"
   :keybinding "G")
 (defengine google
   "http://www.google.com/search?ie=utf-8&oe=utf-8&q=%s"
   :keybinding "g")
 (defengine google-images
   "http://www.google.com/images?hl=en&source=hp&biw=1440&bih=795&gbv=2&aq=f&aqi=&aql=&oq=&q=%s"
   :keybinding "i")
 (defengine google-maps
   "http://maps.google.com/maps?q=%s"
   :docstring "Mappin' it up."
   :keybinding "M")
 (defengine melpa
   "https://melpa.org/#/?q=%s"
   :docstring "Searching on melpa"
    :keybinding "m")
 (defengine project-gutenberg
   "http://www.gutenberg.org/ebooks/search/?query=%s")
 (defengine rfcs
   "http://pretty-rfc.herokuapp.com/search?q=%s")
 (defengine stack-overflow
   "https://stackoverflow.com/search?q=%s"
   :keybinding "s"
   :docstring "Search Stack Overlow")
 (defengine google-translate
   "https://translate.google.com/#view=home&op=translate&sl=en&tl=ru&text=%s"
   :keybinding "t")
 (defengine twitter
   "https://twitter.com/search?q=%s"
   :keybinding "T")
 (defengine wikipedia
   "http://www.wikipedia.org/search-redirect.php?language=en&go=Go&search=%s"
   :keybinding "w"
   :docstring "Searchin' the wikis.")
 (defengine pursuit
   "https://pursuit.purescript.org/search?q=%s"
   :keybinding "p")
 (defengine hoogle
   "https://www.haskell.org/hoogle/?hoogle=%s"
   :keybinding "h")
 (defengine hackage
   "https://hackage.haskell.org/packages/search?terms=%s"
   :keybinding "H")
 (defengine hayoo
   "http://hayoo.fh-wedel.de/?query=%s")
 (defengine wiktionary
   "https://www.wikipedia.org/search-redirect.php?family=wiktionary&language=en&go=Go&search=%s")
 (defengine wolfram-alpha
   "http://www.wolframalpha.com/input/?i=%s")
 (defengine urban-dictionary
   "https://www.urbandictionary.com/define.php?term=%s"
   :keybinding "u")
 (defengine youtube
   "http://www.youtube.com/results?aq=f&oq=&search_query=%s"
   :keybinding "y"))

(use-package counsel-web
 :after (general counsel)
 :quelpa
 (counsel-web :fetcher github :repo "mnewt/counsel-web")
 :custom
 (counsel-web-search-action 'browse-url)
 (counsel-web-suggest-function 'counsel-web-suggest--google)
 (counsel-web-search-function 'counsel-web-search--google)
 :config
 (nmap
  :prefix my/leader
  "S" 'counsel-web-suggest))

 (use-package sx
  :config
  (nmap
    :prefix my/leader
    "' q" 'sx-tab-all-questions
    "' i" 'sx-inbox
    "' o" 'sx-open-link
    "' u" 'sx-tab-unanswered-my-tags
    "' a" 'sx-ask
    "' s" 'sx-search))

(use-package delight
 :config
 (delight
  '((emacs-lisp-mode "elisp" :major)
    (ruby-mode "ruby" :major)
    (elixir-mode "ex" elixir)
    (alchemist-mode "al" alchemist)
    (alchemist-hex-mode "alhex" alchemist)
    (alchemist-test-mode "altest" alchemist)
    (rust-mode "rs" rust)
    (purescript-mode "purs" purescript)
    (javascript-mode "js" js)
    (eldoc-mode "eldoc" eldoc)
    (outline-minor-mode "outl" outline)
    ;; (hi-lock-mode "hi" hi-lock)
    (subword-mode "sw" subword))))

(use-package engine-mode
 :config
 (engine-mode t)
 (engine/set-keymap-prefix (kbd "C-SPC C-SPC"))
 (defengine amazon
   "http://www.amazon.com/s/ref=nb_sb_noss?url=search-alias%3Daps&field-keywords=%s")
 (defengine duckduckgo
   "https://duckduckgo.com/?q=%s"
   :keybinding "d")
 (defengine github
   "https://github.com/search?q=%s&type=Code"
   :keybinding "G")
 (defengine google
   "http://www.google.com/search?ie=utf-8&oe=utf-8&q=%s"
   :keybinding "g")
 (defengine google-images
   "http://www.google.com/images?hl=en&source=hp&biw=1440&bih=795&gbv=2&aq=f&aqi=&aql=&oq=&q=%s"
   :keybinding "i")
 (defengine google-maps
   "http://maps.google.com/maps?q=%s"
   :docstring "Mappin' it up."
   :keybinding "M")
 (defengine melpa
   "https://melpa.org/#/?q=%s"
   :docstring "Searching on melpa"
    :keybinding "m")
 (defengine project-gutenberg
   "http://www.gutenberg.org/ebooks/search/?query=%s")
 (defengine rfcs
   "http://pretty-rfc.herokuapp.com/search?q=%s")
 (defengine stack-overflow
   "https://stackoverflow.com/search?q=%s"
   :keybinding "s"
   :docstring "Search Stack Overlow")
 (defengine google-translate
   "https://translate.google.com/#view=home&op=translate&sl=en&tl=ru&text=%s"
   :keybinding "t")
 (defengine twitter
   "https://twitter.com/search?q=%s"
   :keybinding "T")
 (defengine wikipedia
   "http://www.wikipedia.org/search-redirect.php?language=en&go=Go&search=%s"
   :keybinding "w"
   :docstring "Searchin' the wikis.")
 (defengine pursuit
   "https://pursuit.purescript.org/search?q=%s"
   :keybinding "p")
 (defengine hoogle
   "https://www.haskell.org/hoogle/?hoogle=%s"
   :keybinding "h")
 (defengine hackage
   "https://hackage.haskell.org/packages/search?terms=%s"
   :keybinding "H")
 (defengine hayoo
   "http://hayoo.fh-wedel.de/?query=%s")
 (defengine wiktionary
   "https://www.wikipedia.org/search-redirect.php?family=wiktionary&language=en&go=Go&search=%s")
 (defengine wolfram-alpha
   "http://www.wolframalpha.com/input/?i=%s")
 (defengine urban-dictionary
   "https://www.urbandictionary.com/define.php?term=%s"
   :keybinding "u")
 (defengine youtube
   "http://www.youtube.com/results?aq=f&oq=&search_query=%s"
   :keybinding "y"))

(use-package counsel-web
 :after (general)
 :quelpa
 (counsel-web :fetcher github :repo "mnewt/counsel-web")
 :custom
 (counsel-web-search-action 'browse-url)
 (counsel-web-suggest-function 'counsel-web-suggest--google)
 (counsel-web-search-function 'counsel-web-search--google)
 :config
 (nmap
  :prefix my/leader
  "S" 'counsel-web-suggest))

 (use-package sx
  :config
  (nmap
    :prefix my/leader
    "' q" 'sx-tab-all-questions
    "' i" 'sx-inbox
    "' o" 'sx-open-link
    "' u" 'sx-tab-unanswered-my-tags
    "' a" 'sx-ask
    "' s" 'sx-search))

(use-package diminish
 :config
 (diminish 'abbrev-mode)
 (diminish 'auto-fill-function)
 (with-eval-after-load 'face-remap (diminish 'buffer-face-mode))
 (with-eval-after-load 'with-editor (diminish 'with-editor-mode))
 (eval-after-load "purescript-indentation" '(diminish 'purescript-indentation-mode))
 (eval-after-load "dired" '(diminish 'dired-omit-mode))
 (eval-after-load "hideshow" '(diminish 'hs-minor-mode))
 (eval-after-load "eldoc" '(diminish 'eldoc-mode))
 (eval-after-load "hi-lock" '(diminish 'hi-lock-mode)))

(setq gc-cons-threshold 100000000) ;; 100mb

(setq read-process-output-max (* 1024 1024)) ;; 1mb
