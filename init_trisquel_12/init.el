(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(css-indent-offset 2)
 '(custom-enabled-themes '(tango-dark))
 '(ede-project-directories
   '("/tmp/myproject/include" "/tmp/myproject/src" "/tmp/myproject"))
 '(eglot-extend-to-xref t)
 '(grep-files-aliases
   '(("all" . "* .*") ("el" . "*.el") ("ch" . "*.[ch]") ("c" . "*.c")
     ("cc" . "*.cc *.cxx *.cpp *.C *.CC *.c++")
     ("cchh" . "*.cc *.[ch]xx *.[ch]pp *.[CHh] *.CC *.HH *.[ch]++")
     ("hh" . "*.hxx *.hpp *.[Hh] *.HH *.h++") ("h" . "*.h")
     ("l" . "[Cc]hange[Ll]og*")
     ("am" . "Makefile.am GNUmakefile *.mk") ("m" . "[Mm]akefile*")
     ("tex" . "*.tex") ("texi" . "*.texi") ("asm" . "*.[sS]")
     ("rs" . "*.rs")
     ("common" . "*.tsx *.ts *.py *.sql *.json *.yaml *.toml *.sh")))
 '(markdown-command "pandoc")
 '(org-babel-load-languages '((emacs-lisp . t) (python . t)))
 '(package-archives
   '(("gnu" . "https://elpa.gnu.org/packages/")
     ("nongnu" . "https://elpa.nongnu.org/nongnu/")
     ("melpa" . "https://melpa.org/packages/")))
 '(package-selected-packages
   '(apheleia competitive-programming-snippets eat eglot expand-region
	      gnu-elpa-keyring-update go-mode go-playground magit
	      markdown-mode mermaid-mode python-isort pyvenv
	      racket-mode rg rust-mode rust-playground slime
	      treesit-auto treesit-fold verb yaml-mode yasnippet
	      yasnippet-snippets))
 '(rust-playground-cargo-toml-template
   "[package]\12name = \"foo\"\12version = \"0.1.0\"\12authors = [\"Rust Example <rust-snippet@example.com>\"]\12edition = \"2024\"\12\12[dependencies]")
 '(tool-bar-mode nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:family "DejaVu Sans Mono" :foundry "PfEd" :slant normal :weight normal :height 143 :width normal))))
 '(tab-bar-tab ((t (:inherit tab-bar :background "khaki" :box (:line-width (1 . 1) :style released-button))))))

;;; slime
(setq inferior-lisp-program "/usr/bin/sbcl")

;;; Eglot
(use-package eglot
  :config
  (define-key eglot-mode-map (kbd "C-c r") 'eglot-rename)
  (define-key eglot-mode-map (kbd "C-c o") 'eglot-code-action-organize-imports)
  (define-key eglot-mode-map (kbd "<f5>") 'eglot-code-actions)
  (define-key eglot-mode-map (kbd "<f7>") 'flymake-goto-next-error))

;;;----------------------------------------------------------------
;;; Eglot for Go and Rust
(use-package project
  :config
  (defun project-find-go-module (dir)
    (when-let ((root (locate-dominating-file dir "go.mod")))
      (cons 'go-module root)))
  (cl-defmethod project-root ((project (head go-module)))
    (cdr project))
  (add-hook 'project-find-functions #'project-find-go-module)

  ;; (defun project-find-cargo-package (dir)
  ;;   (when-let ((root (locate-dominating-file dir "Cargo.toml")))
  ;;     (cons 'cargo-package root)))
  ;; (cl-defmethod project-root ((project (head cargo-package)))
  ;;   (cdr project))
  ;; (add-hook 'project-find-functions #'project-find-cargo-package)

  ;; Optional: install eglot-format-buffer as a save hook.
  ;; The depth of -10 places this before eglot's willSave notification,
  ;; so that that notification reports the actual contents that will be saved.
  (defun eglot-format-buffer-before-save ()
    (add-hook 'before-save-hook #'eglot-format-buffer -10 t))
  (add-hook 'go-mode-hook #'eglot-format-buffer-before-save)
  ;; (add-hook 'rust-mode-hook #'eglot-format-buffer-before-save)
  )

;; Configure gopls
(setq-default eglot-workspace-configuration
	      '((:gopls .
			((staticcheck . t)
			 (matcher . "CaseSensitive")))))
;;;----------------------------------------------------------------

(require 'yasnippet)
(yas-reload-all)
(add-hook 'prog-mode-hook #'yas-minor-mode)

(add-hook 'prog-mode-hook #'display-line-numbers-mode)

(setq frame-title-format '(:eval (if (buffer-file-name) "%f" "%b")))

;; expand-region
(require 'expand-region)
(global-set-key (kbd "C-=") 'er/expand-region)

;; rust-mode
(add-hook 'rust-mode-hook
	  (lambda ()
	    (set-fill-column 100)
	    (setq indent-tabs-mode nil)))

;; Verb mode
(with-eval-after-load 'org
  (define-key org-mode-map (kbd "C-c C-r") verb-command-map))

;; Treesit-fold
(global-treesit-fold-mode t)
;; for general folding
(global-set-key (kbd "C-c k o") 'treesit-fold-open)
(global-set-key (kbd "C-c k m") 'treesit-fold-close)
(global-set-key (kbd "C-c k O") 'treesit-fold-open-all)

;; treesit-auto
(use-package treesit-auto
  :custom
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

(use-package apheleia
  :config
  (apheleia-global-mode +1)
  (setf (alist-get 'python-mode apheleia-mode-alist) 'ruff)
  (setf (alist-get 'python-ts-mode apheleia-mode-alist) 'ruff)
  :custom
  (apheleia-formatters-respect-indent-level nil))

(rg-enable-default-bindings)

;;;----------------------------------------------------------------
;;; My utilities
;;;----------------------------------------------------------------
(add-to-list 'load-path (expand-file-name "~/.emacs.d/rui"))
(require 'tree-visualizer)
(require 'json-filter)
(require 'dir-pyenv)
(require 'eldoc-escape-html)
(require 'llm-cost)
(require 'break-alarm)
