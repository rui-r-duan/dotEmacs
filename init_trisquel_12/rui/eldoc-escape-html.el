;; escape HTML in eldoc
(defvar rb--eldoc-html-patterns
  '(("&nbsp;" " ")
    ("&lt;" "<")
    ("&gt;" ">")
    ("&amp;" "&")
    ("&quot;" "\"")
    ("&apos;" "'"))
  "List of (PATTERN . REPLACEMENT) to replace in eldoc output.")

(defun rb--string-replace-all (patterns in-string)
  "Replace all cars from PATTERNS in IN-STRING with their pair."
  (mapc (lambda (pattern-pair)
          (setq in-string
                (string-replace (car pattern-pair) (cadr pattern-pair) in-string)))
        patterns)
  in-string)

(defun rb--eldoc-preprocess (orig-fun &rest args)
  "Preprocess the docs to be displayed by eldoc to replace HTML escapes."
  (let ((doc (car args)))
    ;; The first argument is a list of (STRING :KEY VALUE ...) entries
    ;; we replace the text in each such string
    ;; see docstring of `eldoc-display-functions'
    (when (listp doc)
      (setq doc (mapcar
                 (lambda (doc) (cons
                                (rb--string-replace-all rb--eldoc-html-patterns (car doc))
                                (cdr doc)))
                 doc
                 ))
      )
    (apply orig-fun (cons doc (cdr args)))))

(advice-add 'eldoc-display-in-buffer :around #'rb--eldoc-preprocess)

(provide 'eldoc-escape-html)
