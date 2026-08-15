(defun my/project-generate-venv-locals ()
  "Automatically create .dir-locals.el to activate .venv in the current project."
  (interactive)
  (let* ((project (project-current t))
	 (root (expand-file-name (project-root project)))
	 (venv-path (expand-file-name ".venv/" root)))
    (if (file-directory-p venv-path)
	(let ((default-directory root))
	  ;; Add the variable to .dir-locals.el
	  ;; 'eval' allows running the activation code when a file is opened
	  (add-dir-local-variable
	   'python-mode 'eval
	   `(pyvenv-activate ,venv-path))
	  (message "Generated .dir-locals.el for venv at %s" venv-path))
      (error "No .venv directory found in project root: %s" root))))

(provide 'dir-pyenv)
