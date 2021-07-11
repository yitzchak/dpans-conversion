(cl:in-package #:dpans-conversion.html)

;;; `navigation-sidebar'

(defclass navigation-sidebar (transform:builder-mixin
                              output-directory-mixin
                              static-files-mixin)
  ((%static-files :initform (list #+no (load-time-value
                                        (a:read-file-into-string
                                         ))
                                  (cons #1=#P"navigation.js"
                                        (merge-pathnames
                                         #1# #.(or *compile-file-pathname*
                                                   *load-pathname*)))))
   ;; State
   (%index-files  :accessor index-files
                  :initform nil)
   (%current-file :accessor current-file)))

(defmethod transform:transform-node ((transform navigation-sidebar)
                                     recurse relation relation-args node kind relations &key)
  (funcall recurse))

(defmethod transform:transform-node ((transform navigation-sidebar)
                                     recurse relation relation-args node
                                     (kind (eql :collection)) relations
                                     &key)
  (let* ((builder (transform:builder transform))
         (files   (bp:node-relation builder '(:element . *) node)))
    (setf (index-files transform)
          (map 'list (lambda (name)
                       (find-if (lambda (file)
                                  (equalp (getf (bp:node-initargs builder file) :output-file)
                                          name))
                                files))
               '("chap-0"
                 "symbol-index" "figure-index" "issue-index" "note-indices"
                 "chapter-26")))))    ; glossary

(defmethod transform:transform-node ((transform navigation-sidebar)
                                     recurse relation relation-args node
                                     (kind (eql :output-file)) relations
                                     &key title)
  (setf (current-file transform) node)

  (<> "nav" "sidebar" nil
      (lambda ()
        ;; Entry points
        (span "name" "Entry Points")
        (br)
        (let ((builder (transform:builder transform)))
          (cxml:with-element "ol"
            (map nil (lambda (file)
                       (cxml:with-element "li"
                         (let* ((section (transform::find-ancestor-of-kind builder :section file))
                                (url     (node-url transform node section))
                                (name    (getf (bp:node-initargs builder file) :title) ; (node-name section)
                                         ))
                           (a url name))))
                 (index-files transform))))

        ;; Local TOC
        (cxml:with-element "hr")
        (span "name" title)
        (br)
        (<> "ol" "local-toc" nil recurse))))

(defmethod transform:transform-node ((transform navigation-sidebar)
                                     recurse relation relation-args node
                                     (kind (eql :section)) relations
                                     &key)
  (cxml:with-element "li"
    (let* ((builder (transform:builder transform))
           (name    (if (bp:node-relation builder '(:name . 1) node)
                        (transform::evaluate-to-string
                         builder (bp:node-relation builder '(:name . 1) node))
                        (getf (bp:node-initargs builder node) :name)))
           (url     (node-url transform (current-file transform) node)))
      (a url name))
    (cxml:with-element "ol"             ; TODO avoid if empty
      (cxml:text " ")
      (funcall recurse))))

(defmethod transform:transform-node ((transform navigation-sidebar)
                                     recurse relation relation-args node
                                     (kind (eql :component)) relations
                                     &key)
  (cxml:with-element "li"
    (let* ((builder    (transform:builder transform))
           (name-nodes (bp:node-relation builder '(:name . *) node))
           (first-node (first name-nodes))
           (url        (node-url transform (current-file transform) first-node))
           (names      (map 'list (a:curry #'transform::evaluate-to-string builder) ; TODO what about setf?
                            name-nodes))
           (name       (format nil "~{~A~^, ~}" names)))
      (a url name))))
