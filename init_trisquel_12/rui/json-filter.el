(defun my/extract-har-entries ()
  "Extract specific request/response fields from JSON in current buffer using jq."
  (interactive)
  ;; The jq filter is wrapped in [ ] to ensure a valid single JSON array output
  (let* ((jq-filter "[ (.log.entries // .entries // [])[] | {request: {method: .request.method?, url: .request.url?, postData: {mimeType: .request.postData.mimeType?, text: .request.postData.text?}}, response: {status: .response.status?, statusText: .response.statusText?, httpVersion: .response.httpVersion?, content: {mimeType: .response.content.mimeType?, text: .response.content.text?}}} ]")
         (output-buffer-name "*JQ Filtered Results*")
         (output-buffer (get-buffer-create output-buffer-name)))
    
    (with-current-buffer output-buffer
      (let ((inhibit-read-only t))
        (erase-buffer)))

    ;; shell-command-on-region handles the pipe
    (shell-command-on-region (point-min) (point-max)
                             (format "jq '%s'" jq-filter)
                             output-buffer)

    (pop-to-buffer output-buffer)
    
    ;; Try to apply the best available mode
    (cond
     ((fboundp 'json-ts-mode) (json-ts-mode))
     ((fboundp 'json-mode) (json-mode))
     (t (js-mode)))
    
    ;; Optional: indent the buffer if using js-mode/json-mode
    (indent-region (point-min) (point-max))))

(require 'json)

(defun my/har-extract-and-unescape ()
  "Extract HAR entries, unescape nested JSON, and use temporary buffers to pretty-print."
  (interactive)
  (let* ((json-object-type 'alist)
         ;; 1. Parse the original HAR file
         (har-data (save-excursion
                     (goto-char (point-min))
                     (json-read)))
         (entries (or (cdr (assoc 'entries (cdr (assoc 'log har-data))))
                      (cdr (assoc 'entries har-data))
                      []))
         (output-buffer (get-buffer-create "*HAR Unescaped View*"))
         ;; 2. Helper function to simulate 'json-pretty-print' on a string
         (pretty-print-json-string 
          (lambda (str)
            (if (and str (stringp str) (string-match-p "^{" str))
                (with-temp-buffer
                  (insert str)
                  (condition-case nil
                      (progn
                        (json-pretty-print-buffer)
                        (buffer-string))
                    (error str))) ; If it fails, return raw string
              (or str "None")))))

    (with-current-buffer output-buffer
      (let ((inhibit-read-only t))
        (erase-buffer)
        
        (seq-doseq (entry entries)
          (let* ((req (cdr (assoc 'request entry)))
                 (resp (cdr (assoc 'response entry)))
                 (req-text (cdr (assoc 'text (cdr (assoc 'postData req)))))
                 (resp-text (cdr (assoc 'text (cdr (assoc 'content resp))))))

            ;; 3. Insert Entry Metadata
            (insert (format "URL:    %s\nMETHOD: %s\nSTATUS: %s\n"
                            (cdr (assoc 'url req))
                            (cdr (assoc 'method req))
                            (cdr (assoc 'status resp))))
            
            ;; 4. Insert Multi-line Pretty-Printed Request
            (insert "\n[Request Body]\n")
            (insert (funcall pretty-print-json-string req-text))
            
            ;; 5. Insert Multi-line Pretty-Printed Response
            (insert "\n\n[Response Body]\n")
            (insert (funcall pretty-print-json-string resp-text))
            
            (insert "\n\n" (make-string 60 ?-) "\n\n")))
        
        (goto-char (point-min))
        ;; Use js-mode for syntax highlighting of the result
        (js-mode)
        (pop-to-buffer (current-buffer))))))

(provide 'json-filter)
