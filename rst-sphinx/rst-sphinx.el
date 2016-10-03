;;; rst-sphinx.el --- Build Sphinx projects.

;; Copyright (C) 2012 Wei-Wei Guo.

;; Author: Wei-Wei Guo <wwguocn at gmail dot com>
;; Version: 0.1
;;
;; This file is published under the GNU Gerneral Public License,
;; see <http://www.gnu.org/licenses/>.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:

;; This file enable building Sphinx project in Emacs.

;;; Code:

(defgroup rst-sphinx nil
  "Settings for support of conversion of reStructuredText
document with \\[rst-sphinx]."
  :group 'rst
  :version "24.5")

(defvar rst-sphinx-command "sphinx-build -b"
  "Sphinx compile command.")

(defvar rst-sphinx-builder
  '((html . "html")
    (latex . "xelatex"))
  "Table describing the builder used to compile.")

(defvar rst-sphinx-source nil
  "The Sphinx project source directory.")

(defvar rst-sphinx-target nil
  "The Sphinx project target directory.")

(defvar rst-sphinx-project nil
  "The Sphinx project name.")

(defvar rst-sphinx-source-file nil
  "Current Sphinx project source file.")

(defvar rst-sphinx-source-buffer nil
  "Current Sphinx project source file buffer.")

(defcustom rst-sphinx-target-parent nil
  "The Sphinx project target parent directory."
  :group 'rst-builders
  :type 'directory)

(defcustom rst-sphinx-target-projects nil
  "The Sphinx project target project directories."
  :group 'rst-builders)

(defun rst-sphinx-find-conf ()
  "Look for the configuration file in the parents of the current path."
  ;; (interactive)
  (let* ((file-name "conf.py")
        (buffer-file (buffer-file-name))
        (dir (file-name-directory buffer-file)))
    ;; Move up in the dir hierarchy till we find a change log file.
    (while (or (not (file-exists-p (concat dir file-name))))
      ;; Move up to the parent dir and try again.
      (setq buffer-file (directory-file-name 
                         (file-name-directory buffer-file)))
      (setq dir (file-name-directory buffer-file)))
    (setq dir (directory-file-name
               (file-name-directory buffer-file)))
    (setq rst-sphinx-source dir)
    (setq rst-sphinx-project (file-name-nondirectory dir))
    ;; not depend on local variables, put here just for convience.
    (setq rst-sphinx-target 
                            (expand-file-name  
                             (nth 2 (assoc rst-sphinx-project 
                                           rst-sphinx-target-projects))
                             rst-sphinx-target-parent))
    (setq rst-sphinx-source-buffer (current-buffer)
          rst-sphinx-source-file (buffer-file-name))
  ))


(require 'compile)

(defun rst-sphinx-compile ()
  "Compile Sphinx project."
  (interactive)
  (if (not (string= (file-name-extension (buffer-file-name)) "rst"))
      (print "Not a ReStructerdText file.")
    (progn
      (rst-sphinx-find-conf)
      (let ((builder (nth 1 (assoc rst-sphinx-project 
                                   rst-sphinx-target-projects))))
        (compile (mapconcat 'identity 
                            (list rst-sphinx-command
                                  (cdr (assoc builder rst-sphinx-builder))
                                  rst-sphinx-source
                                  rst-sphinx-target) 
                            " "))
        ))))

(defun rst-sphinx-target-open ()
  "Open builded Sphinx project file."
  (interactive)
  (if (not (string= (file-name-extension (buffer-file-name)) "rst"))
      (print "Not a ReStructerdText file.")
    (progn
      (rst-sphinx-find-conf)
      (let ((builder (nth 1 (assoc rst-sphinx-project 
                                   rst-sphinx-target-projects)))
            (buffer-file (nth 1 (split-string
                                 (file-name-sans-extension rst-sphinx-source-file)
                                 rst-sphinx-source))))
        (if (eq builder 'html)
            (start-process-shell-command 
             "Sphinx HTML project viewing" nil
             (mapconcat 'identity 
                        (list rst-slides-program
                              (concat rst-sphinx-target buffer-file ".html"))
                        " ")))
        (if (eq builder 'latex)
            (let (type)
              (setq type (completing-read "Which file? (TeX, PDF): " '("tex" "pdf")))
              (if (string= "tex" type)
                  (progn
                    (setq rst-sphinx-tex-file 
                          (car (directory-files rst-sphinx-target nil ".tex")))
                    (find-file (expand-file-name rst-sphinx-tex-file rst-sphinx-target))))
              (if (string= "pdf" type)
                  (if (directory-files rst-sphinx-target nil ".pdf")
                      (start-process-shell-command 
                       "Sphinx PDF project viewing" nil
                       (mapconcat 'identity 
                                  (list rst-pdf-program
                                        (expand-file-name 
                                         (car (directory-files 
                                               rst-sphinx-target nil ".pdf"))
                                         rst-sphinx-target))
                                  " "))
                    (print "Cannot find PDF file.")))))))))

(defun rst-sphinx-switch-buffer ()
  "Switch to Sphinx project file buffer."
  (interactive)
  (switch-to-buffer rst-sphinx-source-buffer))


(provide 'rst-sphinx)
