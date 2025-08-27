(defvar elpaca-installer-version 0.11)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))
(elpaca elpaca-use-package
  ;; Enable use-package :ensure support for Elpaca.
  (elpaca-use-package-mode))

;; --- Theme ---
(use-package catppuccin-theme
  :ensure t
  :config
  ;; Load the theme after it's installed.
  ;; Choose your favorite flavor: latte, frappe, macchiato, or mocha
  (load-theme 'catppuccin t))

;; --- Basic UI & Keybindings ---
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

(use-package windmove
  :bind (("C-c ;" . windmove-right)
         ("C-c j" . windmove-left)
         ("C-c k" . windmove-down)
         ("C-c l" . windmove-up)))

;; --- Programming & Development ---
(setq make-backup-files nil)



(add-hook 'c++-mode-hook 'display-line-numbers-mode)
(add-hook 'emacs-lis-mode-hook 'display-line-numbers-mode)

(use-package eglot
  :ensure t
  ;; Correct hook syntax: (mode . function)
  :hook ((c++-mode . eglot-ensure)
         (emacs-lisp-mode . eglot-ensure)))

(use-package flymake
  :ensure t)

(use-package smartparens
  :ensure t
  :hook ((c++-mode . smartparens-mode)
         (emacs-lisp-mode . smartparens-mode)))

(use-package company
  :ensure t
  :hook ((c++-mode . company-mode)
         (emacs-lisp-mode . company-mode)))

(use-package vterm
  :ensure t)
