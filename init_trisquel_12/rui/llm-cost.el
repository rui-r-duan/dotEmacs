(defun llm-cost (input output)
  (+ (* 0.00625 (/ input 1000))
     (* 0.03 (/ output 1000))))

(provide 'llm-cost)
