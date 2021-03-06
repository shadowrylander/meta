;;; meta.el --- a simple package                     -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Jeet Ray

;; Author: Jeet Ray <aiern@protonmail.com>
;; Keywords: lisp
;; Version: 0.0.1

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Put a description of the package here

;;; Code:

(require 'meq)
(require 'which-key)
(require 'deino)

(defun meta--replace-spaces (str) (s-replace " " "/" str))
(defun meta--construct-name (str) (meta--replace-spaces (concat "hydreigon/" str)))

(defmacro meta* (parent first-call name key func*)
    (let* ((func (intern func*))
            (ds (deino--create-dataset
                name
                key
                parent
                func
                #'(lambda
                    (str)
                    (interactive)
                    (meta--construct-name (concat name "/" str)))))

            (next-key (string-join (cdr (d--g ds :keys)) " "))
            (next-deino-body (if (d--g ds :two-key) func (meq/inconcat (d--g ds :next-name) "/body")))
            (deino-funk (meq/inconcat "defdeino" (if (d--g ds :current-body-plus) "+" "")))
            (deino-list (if (d--g ds :current-body-plus) (list nil) '((:color blue) nil ("`" nil "cancel")))))
        (when first-call (eval `(defdeino+
                                    ,(intern (meta--construct-name name))
                                    nil
                                    (,(d--g ds :carkeys)
                                        ,(d--g ds :current-body)
                                        ,(symbol-name (d--g ds :current-body))))))
        (unless (d--g ds :one-key)
            (eval `(meta* ,(d--g ds :current-parent) nil ,name ,next-key ,func*))
            `(,(meq/inconcat "defdeino" (if (d--g ds :current-body-plus) "+" ""))
                ,(intern (d--g ds :current-name))
                ,@(if (d--g ds :current-body-plus) (list nil) '((:color blue) nil ("`" nil "cancel")))
                (,(d--g ds :spare-keys)
                    ,next-deino-body
                    ,(symbol-name next-deino-body))))))

;;;###autoload
(defmacro meta (keymap)
    (let* ((name* (symbol-name keymap))
            (name (meta--construct-name name*)))
        (eval `(defdeino ,(intern name) (:color blue) nil ("`" nil "cancel")))
        (mapc #'(lambda (kons) (interactive)
                    (eval `(meta*
                        nil
                        t
                        ,name*
                        ,(car kons)
                        ,(cdr kons))))
            (eval `(which-key--get-keymap-bindings ,keymap nil nil t))) nil))

;;;###autoload
(defmacro meta-evil (keymap)
    (let* ((name* (symbol-name keymap))
            (name (meta--construct-name name*)))
        (eval `(defdeino ,(intern name) (:color blue) nil ("`" nil "cancel")))
        (mapc #'(lambda (kons) (interactive)
                    (eval `(meta*
                        nil
                        t
                        ,name*
                        ,(car kons)
                        ,(cdr kons))))
            (eval `(which-key--get-keymap-bindings ,keymap nil nil t t))) nil))

;;;###autoload
(defmacro meta-aiern (keymap)
    (let* ((name* (symbol-name keymap))
            (name (meta--construct-name name*)))
        (eval `(defdeino ,(intern name) (:color blue) nil ("`" nil "cancel")))
        (mapc #'(lambda (kons) (interactive)
                    (eval `(meta*
                        nil
                        t
                        ,name*
                        ,(car kons)
                        ,(cdr kons))))
            (eval `(which-key--get-keymap-bindings ,keymap nil nil t nil t))) nil))

;;;###autoload
(defmacro meta-rename (keymap key &rest args)
    (let* ((name (symbol-name keymap)))
        `(defdeino+
            ,(intern (meta--construct-name name))
            nil
            (,key
                ,(meq/inconcat (meta--construct-name (concat name "/" key)) "/body")
                ,@args))))

;;;###autoload
(defmacro meta-rename+ (keymap key &rest args)
    (let* ((second-constructor `(lambda (str) (interactive)
                                    (meta--construct-name (concat ,(symbol-name keymap) "/" str))))
            (first-constructor `(lambda (keys) (interactive)
                                    (deino--construct-name+ keys #',second-constructor))))
        `(deino--nested-rename key #',first-constructor args)))

(with-eval-after-load 'use-package
    ;; Primarily adapted from https://gitlab.com/to1ne/use-package-hydra/-/blob/master/use-package-hydra.el

    ;; Adapted From: https://github.com/jwiegley/use-package/blob/master/use-package-core.el#L1153
    ;;;###autoload
    (defalias 'use-package-normalize/:meta 'use-package-normalize-forms)

    ;; Adapted From: https://gitlab.com/to1ne/use-package-hydra/-/blob/master/use-package-hydra.el#L79
    ;;;###autoload
    (defun use-package-handler/:meta (name keyword args rest state)
        (use-package-concat (mapcar #'(lambda (def) `(meta ,@def)) args)
        (use-package-process-keywords name rest state)))

    (add-to-list 'use-package-keywords :meta t)

    ;;;###autoload
    (defalias 'use-package-normalize/:meta-evil 'use-package-normalize-forms)

    ;;;###autoload
    (defun use-package-handler/:meta-evil (name keyword args rest state)
        (use-package-concat (mapcar #'(lambda (def) `(meta-evil ,@def)) args)
        (use-package-process-keywords name rest state)))

    (add-to-list 'use-package-keywords :meta-evil t)

    ;;;###autoload
    (defalias 'use-package-normalize/:meta-aiern 'use-package-normalize-forms)

    ;;;###autoload
    (defun use-package-handler/:meta-aiern (name keyword args rest state)
        (use-package-concat (mapcar #'(lambda (def) `(meta-aiern ,@def)) args)
        (use-package-process-keywords name rest state)))

    (add-to-list 'use-package-keywords :meta-aiern t)

    ;;;###autoload
    (defalias 'use-package-normalize/:meta-rename 'use-package-normalize-forms)

    ;;;###autoload
    (defun use-package-handler/:meta-rename (name keyword args rest state)
    "Generate meta-rename with NAME for `:meta-rename' KEYWORD.
    ARGS, REST, and STATE are prepared by `use-package-normalize/:meta-rename'."
    (use-package-concat
    (mapcar #'(lambda (def) `(meta-rename ,@def)) args)
    (use-package-process-keywords name rest state)))

    (add-to-list 'use-package-keywords :meta-rename t)

    ;;;###autoload
    (defalias 'use-package-normalize/:meta-rename+ 'use-package-normalize-forms)

    ;;;###autoload
    (defun use-package-handler/:meta-rename+ (name keyword args rest state)
    "Generate meta-rename+ with NAME for `:meta-rename+' KEYWORD.
    ARGS, REST, and STATE are prepared by `use-package-normalize/:meta-rename+'."
    (use-package-concat
    (mapcar #'(lambda (def) `(meta-rename+ ,@def)) args)
    (use-package-process-keywords name rest state)))

    (add-to-list 'use-package-keywords :meta-rename+ t))

(provide 'meta)
;;; meta.el ends here
