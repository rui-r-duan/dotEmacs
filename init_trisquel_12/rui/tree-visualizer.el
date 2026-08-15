;;; tree-visualizer.el --- Visualize a binary tree from a LeetCode-style string in Emacs using SVG

(require 'svg)

(defun make-node (value)
  "Create a node with VALUE and null left and right children."
  (list value nil nil))

(defun node-value (node)
  "Get the value of NODE."
  (car node))

(defun node-left (node)
  "Get the left child of NODE."
  (cadr node))

(defun node-right (node)
  "Get the right child of NODE."
  (caddr node))

(defun set-left (node left)
  "Set the left child of NODE to LEFT."
  (setcar (cdr node) left))

(defun set-right (node right)
  "Set the right child of NODE to RIGHT."
  (setcar (cddr node) right))

(defun parse-leetcode-tree (s)
  "Parse a LeetCode-style tree string (e.g., '[3,9,20,null,null,15,7]') into a tree."
  (when (or (string-empty-p s) (string= s "[]"))
    (user-error "Invalid input: empty tree"))
  ;; Remove brackets and split by commas
  (let* ((s (string-trim s))
         (s (substring s 1 -1))
         (values (split-string s "," t " \t\n\r")))
    (when (null values)
      (user-error "Invalid input: no values"))
    ;; Convert to list of values or nil for null
    (let ((nodes (mapcar (lambda (val)
                           (if (string= (string-trim val) "null")
                               nil
                             (string-to-number (string-trim val))))
                         values)))
      (when (null (car nodes))
        (user-error "Invalid input: root cannot be null"))
      ;; Build tree using level-order traversal
      (let ((root (make-node (car nodes)))
            (queue nil)) ;; Initialize queue as empty
        ;; Enqueue the root node directly
        (setq queue (nconc queue (list root)))
        (let ((i 1))
          (while (and queue (< i (length nodes)))
            (let ((current (pop queue)))
              ;; Assign left child
              (when (< i (length nodes))
                (unless (null (nth i nodes))
                  (let ((new-node (make-node (nth i nodes))))
                    (set-left current new-node)
                    (setq queue (nconc queue (list new-node)))))
                (setq i (+ i 1)))
              ;; Assign right child
              (when (< i (length nodes))
                (unless (null (nth i nodes))
                  (let ((new-node (make-node (nth i nodes))))
                    (set-right current new-node)
                    (setq queue (nconc queue (list new-node)))))
                (setq i (+ i 1)))))
          root)))))

(defun tree-height (node)
  "Calculate the height of the tree rooted at NODE."
  (if (null node)
      0
    (1+ (max (tree-height (node-left node))
             (tree-height (node-right node))))))


(defun draw-tree (node)
  "Draw the binary tree rooted at NODE as an SVG and display it."
  (when (null node)
    (user-error "Cannot draw empty tree"))
  (let* ((height (tree-height node))
         (node-radius 20)
         (level-height 50)
         (svg-width (* (expt 2 height) node-radius 1.5))
         (svg-height (* height level-height))
         (svg (svg-create svg-width svg-height)))
    ;; Draw nodes and edges
    (cl-labels ((draw-node (n x y level)
                  (when n
                    ;; Draw node as a circle with value
                    (svg-circle svg x y node-radius :fill "white" :stroke "orange" :stroke-width 2)
                    (svg-text svg (number-to-string (node-value n))
                              :x x :y (+ y 5) :text-anchor "middle" :font-size 16 :fill "black")
                    ;; Draw children nodes
                    (let* ((child-y (+ y level-height))
                           (offset (max node-radius (/ svg-width (expt 2 (+ level 2)))))
                           (left-x (- x offset))
                           (right-x (+ x offset)))
                      (when (node-left n)
			(draw-node (node-left n) left-x child-y (+ level 1)))
                      (when (node-right n)
			(draw-node (node-right n) right-x child-y (+ level 1))))))
		(draw-edges (n x y level)
                  (when n
                    (let* ((child-y (+ y level-height))
                           (offset (max node-radius (/ svg-width (expt 2 (+ level 2)))))
                           (left-x (- x offset))
                           (right-x (+ x offset)))
                      (when (node-left n)
			(svg-line svg x y left-x child-y :stroke "orange" :stroke-width 2)
			(draw-edges (node-left n) left-x child-y (+ level 1)))
                      (when (node-right n)
			(svg-line svg x y right-x child-y :stroke "orange" :stroke-width 2)
			(draw-edges (node-right n) right-x child-y (+ level 1)))))))
      ;; Start drawing from root
      (draw-edges node (/ svg-width 2.0) node-radius 0)
      (draw-node node (/ svg-width 2.0) node-radius 0))
    ;; Display SVG in a new buffer
    (with-current-buffer (get-buffer-create "*Tree Visualization*")
      (erase-buffer)
      (insert-image (svg-image svg))
      (image-mode)
      (pop-to-buffer (current-buffer)))))

(defun my/leetcode-tree (region-start region-end)
  "Visualize a LeetCode-style tree string from the current region in a GUI buffer.
If no region is active, prompt for input."
  (interactive "r")
  (let ((s (if (use-region-p)
               (buffer-substring-no-properties region-start region-end)
             (read-string "Enter LeetCode tree string (e.g., [3,9,20,null,null,15,7]): "))))
    (let ((tree (parse-leetcode-tree s)))
      (draw-tree tree))))

(provide 'tree-visualizer)

