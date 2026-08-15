 ;;; break-alarm.el --- Break alarm with progress bar and animate-string

(require 'animate)

;;; State

(defvar break-alarm-timer nil "Timer that fires the alarm.")
(defvar break-alarm-progress-timer nil "Timer updating the progress bar.")
(defvar break-alarm-anim-timer nil "Timer that re-runs the text animation.")
(defvar break-alarm-fired-time nil "Float-time when the alarm fired.")
(defvar break-alarm-message "BREAK TIME" "Main alarm message.")

;;; Layout (line numbers, 0-indexed from top of buffer)
(defconst break-alarm--vpos-bar  1 "Line for the progress bar.")
(defconst break-alarm--vpos-msg  3 "Line for the main animated message.")
(defconst break-alarm--vpos-quit 5 "Line for the dismiss hint.")

;;; Internals

(defun break-alarm--buffer ()
  (get-buffer-create "*Break Alarm*"))

(defun break-alarm--update-progress ()
  "Rewrite only the progress-bar line in the alarm buffer."
  (let* ((buf (break-alarm--buffer))
         (win (get-buffer-window buf t)))
    (when win
      (with-current-buffer buf
        (let* ((inhibit-read-only t)
               (elapsed  (round (- (float-time) break-alarm-fired-time)))
               ;; Progress caps at 20 blocks after 5 minutes (300s)
               (bar-len  (min 20 (/ elapsed 15)))
               (bar      (concat (make-string bar-len ?█)
                                 (make-string (- 20 bar-len) ?░))))
          (save-excursion
            (goto-char (point-min))
            (forward-line break-alarm--vpos-bar)
            (delete-region (point) (line-end-position))
            (insert (format "  [%s]  %dm %02ds elapsed"
                            bar (/ elapsed 60) (% elapsed 60)))))))))

(defun break-alarm--run-animation ()
  "Re-animate the message lines using animate-string."
  (let* ((buf (break-alarm--buffer))
         (win (get-buffer-window buf t)))
    (when win
      (with-selected-window win
        (with-current-buffer buf
          (let ((inhibit-read-only t))
            (animate-string (concat "  " break-alarm-message)
                            break-alarm--vpos-msg)
            (animate-string "  Press q to dismiss"
                            break-alarm--vpos-quit)))))))

(defun break-alarm--show ()
  "Open the side window, seed the buffer, and start both timers."
  (setq break-alarm-fired-time (float-time))

  (let ((buf (break-alarm--buffer)))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        ;; Pre-fill exactly enough blank lines so animate-string has rows to target
        (erase-buffer)
        (insert (make-string (1+ break-alarm--vpos-quit) ?\n)))
      (local-set-key (kbd "q") #'break-alarm-dismiss))

    (display-buffer buf
                    '((display-buffer-in-side-window)
                      (side . bottom)
                      (slot . 0)
                      (window-height . 8))))

  ;; Cancel any leftover timers
  (dolist (sym '(break-alarm-progress-timer break-alarm-anim-timer))
    (when (timerp (symbol-value sym))
      (cancel-timer (symbol-value sym))))

  ;; Progress bar: update every second
  (setq break-alarm-progress-timer
        (run-at-time 0 1 #'break-alarm--update-progress))

  ;; Animation: run immediately, then repeat every 9 seconds
  (setq break-alarm-anim-timer
        (run-at-time 0 9 #'break-alarm--run-animation)))

;;; Public API

(defun break-alarm-dismiss ()
  "Dismiss the alarm window and cancel all running timers."
  (interactive)
  (dolist (sym '(break-alarm-progress-timer break-alarm-anim-timer))
    (when (timerp (symbol-value sym))
      (cancel-timer (symbol-value sym))
      (set sym nil)))
  (let ((win (get-buffer-window "*Break Alarm*" t)))
    (when win (delete-window win)))
  (when (get-buffer "*Break Alarm*")
    (kill-buffer "*Break Alarm*")))

(defun break-alarm-cancel ()
  "Cancel the pending alarm before it fires."
  (interactive)
  (when (timerp break-alarm-timer)
    (cancel-timer break-alarm-timer)
    (setq break-alarm-timer nil)
    (message "Break alarm cancelled.")))

;;;###autoload
(defun my/break-alarm-start (&optional delay-minutes message)
  "Schedule a break alarm in DELAY-MINUTES (default 3) with MESSAGE."
  (interactive
   (list (read-number "Minutes until break: " 3)
         (read-string "Alarm message: " "BREAK TIME")))
  (let ((delay (or delay-minutes 3))
        (msg   (or message "BREAK TIME")))
    (setq break-alarm-message msg)
    (when (timerp break-alarm-timer)
      (cancel-timer break-alarm-timer))
    (setq break-alarm-timer
          (run-at-time (* delay 60) nil #'break-alarm--show))
    (message "Break alarm set: %d minute(s) — \"%s\"" delay msg)))

(provide 'break-alarm)
