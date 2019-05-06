(defun my/emacs-file-path (name)
  (expand-file-name name user-emacs-directory))

(defun my/generate-config ()
  ;; We can't tangle without org!
  (require 'org)
  ;; Open the configuration
  (find-file (my/emacs-file-path "config.org"))
  ;; Tangle it
  (org-babel-tangle)
  ;; Finally byte-compile it
  (byte-compile-file (my/emacs-file-path "config.el")))

(let
  ((config-file (my/emacs-file-path "config.el")))
  (when (not (file-exists-p config-file)) (my/generate-config))
  (load-file config-file))
