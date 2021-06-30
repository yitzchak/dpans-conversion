(cl:in-package #:dpans-conversion.html)

;;; File output

(defun filename-and-relative-path (filename output-directory)
  (let* ((filename (merge-pathnames filename output-directory))
         (enough   (uiop:enough-pathname filename output-directory))
         (depth    (1- (length (pathname-directory enough))))
         (ups      (if (plusp depth)
                       (make-list depth :initial-element :up)
                       '()))
         (relative (make-pathname :directory `(:relative ,@ups))))
    (values filename relative)))

(defun call-with-html-document (continuation filename output-directory
                                &key title use-mathjax use-sidebar)
  (multiple-value-bind (filename relative)
      (filename-and-relative-path filename output-directory)
    (ensure-directories-exist filename)
    (a:with-output-to-file (stream filename
                                   :element-type '(unsigned-byte 8)
                                   :if-exists    :supersede)
      (cxml:with-xml-output (cxml:make-octet-stream-sink stream ; :omit-xml-declaration-p t
                                                         )
        #+no (cxml:unescaped "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">")
        (cxml:unescaped "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1 plus MathML 2.0//EN\"
  \"http://www.w3.org/Math/DTD/mathml2/xhtml-math11-f.dtd\">")
        ;; (cxml:unescaped "<!DOCTYPE html>")
        (cxml:with-element "html"
          (cxml:attribute "xmlns" "http://www.w3.org/1999/xhtml")
          (cxml:with-element "head"
            (cxml:with-element "meta"
              (cxml:attribute "charset" "utf-8"))
            (cxml:with-element "link"
              (cxml:attribute "rel" "stylesheet")
              (cxml:attribute "type" "text/css")
              (cxml:attribute "href" (namestring
                                      (merge-pathnames "style.css" relative))))
            #+no (when use-mathjax
                   (cxml:with-element "script"
                     (cxml:attribute "src" "https://polyfill.io/v3/polyfill.min.js?features=es6")
                     (cxml:text " "))
                   (cxml:with-element "script"
                     (cxml:attribute "id" "MathJax-script")
                     (cxml:attribute "src" "https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js")
                     (cxml:text " "))
                   (cxml:with-element "script"
                     (cxml:attribute "type" "text/javascript")
                     (cxml:text "MathJax = {
  options: {
    includeHtmlTags: {         //  HTML tags that can appear within math
        span: '\n'
    }
  }
}")))
            (when use-sidebar
              (cxml:with-element "script"
                (cxml:attribute "src" (namestring
                                       (merge-pathnames "navigation.js" relative)))
                (cxml:text " ")))
            (when title
              (cxml:with-element "title"
                (cxml:text title))))
          (cxml:with-element "body"
            (cxml:with-element "main"
              (funcall continuation stream))
            (cxml:with-element "footer"
              (cxml:text "Copyright © 2021 Jan Moringen"))))))))

(defmacro with-html-document ((stream-var filename output-directory
                               &rest args &key title use-mathjax use-sidebar)
                              &body body)
  (declare (ignore title use-mathjax use-sidebar))
  `(call-with-html-document
    (lambda (,stream-var) (declare (ignorable ,stream-var)),@body)
    ,filename ,output-directory ,@args))

;;; Element shortcuts

(defun class-attribute (class-or-classes)
  (typecase class-or-classes
    (null)
    (cons (cxml:attribute "class" (format nil "~{~A~^ ~}" class-or-classes)))
    (string (cxml:attribute "class" class-or-classes))))

(defun nbsp ()
  (cxml:unescaped "&nbsp;"))

(defun br ()
  (cxml:with-element "br"))

(defun span (class continuation)
  (cxml:with-element "span"
    (class-attribute class)
    (funcall continuation)))

(defun span* (class id continuation)
  (cxml:with-element "span"
    (class-attribute class)
    (when id (cxml:attribute "id" id))
    (funcall continuation)))

(defun div (class continuation)
  (cxml:with-element "div"
    (class-attribute class)
    (funcall continuation)))

(defun div* (class id continuation)
  (cxml:with-element "div"
    (class-attribute class)
    (when id (cxml:attribute "id" id))
    (funcall continuation)))

(defun a (url continuation)
  (cxml:with-element "a"
    (cxml:attribute "href" url)
    (funcall continuation)))

(defun a* (url class continuation)
  (cxml:with-element "a"
    (class-attribute class)
    (cxml:attribute "href" url)
    (funcall continuation)))

(defun h* (level class name-or-continuation)
  (cxml:with-element (coerce (format nil "h~D" level) '(and string (not base-string)))
    (class-attribute class)
    (if (stringp name-or-continuation)
        (cxml:text name-or-continuation)
        (funcall name-or-continuation))))

(defun h (level name-or-continuation)
  (h* level nil name-or-continuation))
