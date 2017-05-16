;; Package manager
(when (>= emacs-major-version 24)
  (require 'package)
  (add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/") t)
  (package-initialize))

(setq-default fill-column 80)

(defadvice clone-indirect-buffer (around associate-filename activate)
  "Associate the original filename with the cloned buffer."
  (let ((filename buffer-file-name))
    ad-do-it
    (setq buffer-file-name filename)))

(ido-mode t)

;; Use meta + direction to move from window to window
(global-set-key (kbd "M-<up>") 'windmove-up)
(global-set-key (kbd "M-<down>") 'windmove-down)
(global-set-key (kbd "M-<right>") 'windmove-right)
(global-set-key (kbd "M-<left>") 'windmove-left)

;; Compile & test shortcuts
(global-set-key (kbd "C-c m") 'compile)

;; Follow compilation output
(setq compilation-scroll-output t)

;; by default, don't word wrap
(setq-default truncate-lines t)

;; ... except in compilation buffers
(defun my-compilation-mode-hook ()
  (setq truncate-lines nil) ;; automatically becomes buffer local
  (set (make-local-variable 'truncate-partial-width-windows) nil))
(add-hook 'compilation-mode-hook 'my-compilation-mode-hook)

;; use ibuffer instead of buffer-menu or buffer-list
(global-set-key "\C-x\C-b" 'ibuffer)

;; split window horizontally by default when using ediff
(setq ediff-split-window-function 'split-window-horizontally)
(setq ediff-merge-split-window-function 'split-window-horizontally)

;; Swap standard binding for RET and C-j when in c-like modes
(add-hook 'c-mode-common-hook '(lambda ()
  (local-set-key (kbd "RET") 'newline-and-indent)))
(add-hook 'c-mode-common-hook '(lambda ()
  (local-set-key (kbd "C-j") 'newline)))

;; Inside shell, track directory via prompt
(setq dirtrack-list '("^sandro@ubuntu:\\([^\\$]*\\)" 1 nil))

;; Set to dirtrack mode when inside shell
(add-hook 'shell-mode-hook
          #'(lambda ()
              (dirtrack-mode 1)))

;; Create a new, indented line above the current line
(defun add-line-above ()
  (interactive)
  (beginning-of-line)
  (insert "\n")
  (previous-line)
  (indent-for-tab-command))

;; Create a new, indented line below the current line
(defun add-line-below ()
  (interactive)
  (end-of-line)
  (newline-and-indent))

;; Bind the create-new-line functions to handy shortcuts
(global-set-key (kbd "<C-return>") 'add-line-below)
(global-set-key (kbd "<C-S-return>") 'add-line-above)

;; Horizontally centre point
(defun my-horizontal-recenter ()
  "make the point horizontally centered in the window"
  (interactive)
  (let ((mid (/ (window-width) 2))
        (line-len (save-excursion (end-of-line) (current-column)))
        (cur (current-column)))
    (if (< mid cur)
        (set-window-hscroll (selected-window)
                            (- cur mid)))))

;; Keybinding for above
(global-set-key (kbd "C-S-l") 'my-horizontal-recenter)

;; Scroll up and down by just one line
(defun scroll-up-one-line()
  (interactive)
  (scroll-up 1))

(defun scroll-down-one-line()
  (interactive)
  (scroll-down 1))

;; Keybinding for above
(global-set-key (kbd "C-.") 'scroll-down-one-line)
(global-set-key (kbd "C-,") 'scroll-up-one-line)

;; Duplicate lines
;; From: http://stackoverflow.com/a/4717026
(defun duplicate-line-or-region (&optional n)
  "Duplicate current line, or region if active.
With argument N, make N copies.
With negative N, comment out original line and use the absolute value."
  (interactive "*p")
  (let ((use-region (use-region-p)))
    (save-excursion
      (let ((text (if use-region        ;Get region if active, otherwise line
                      (buffer-substring (region-beginning) (region-end))
                    (prog1 (thing-at-point 'line)
                      (end-of-line)
                      (if (< 0 (forward-line 1)) ;Go to beginning of next line, or make a new one
                          (newline))))))
        (dotimes (i (abs (or n 1)))     ;Insert N times, or once if not specified
          (insert text))))
    (if use-region nil                  ;Only if we're working with a line (not a region)
      (let ((pos (- (point) (line-beginning-position)))) ;Save column
        (if (> 0 n)                             ;Comment out original with negative arg
            (comment-region (line-beginning-position) (line-end-position)))
        (forward-line 1)
        (forward-char pos)))))

(global-set-key (kbd "C-c d") 'duplicate-line-or-region)

;; Use winner-mode for preserving window configuration
(when (fboundp 'winner-mode)
  (winner-mode 1))

;; Expand-region
(require 'expand-region)
(global-set-key (kbd "C-=") 'er/expand-region)

;; Auto-complete
(global-set-key (kbd "<C-tab>") 'dabbrev-completion)

;; Magit
(global-set-key (kbd "C-x g") 'magit-status)

;; web-mode
(require 'web-mode)
(add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode))

;; EMMS
(add-to-list 'load-path "~/emms/lisp/")
(require 'emms-setup)
(emms-standard)
(emms-default-players)

;; rsync folder - source https://oremacs.com/2016/02/24/dired-rsync/
(defun ora-dired-rsync (dest)
  (interactive
   (list
    (read-file-name "Rsync to: ")))
  ;; store all selected files into "files" list
  (let (;; the rsync command
        (tmtxt/rsync-command "rsync -arvz --progress ")
	(src default-directory))
    ;; Strip /ssh: from directory
    (if (and (> (length src) 5)
	     (string= "/ssh:" (substring src 0 5)))
	(setq src (substring src 5)))
    ;; append the source and destination
    (setq tmtxt/rsync-command
          (concat tmtxt/rsync-command src " " dest))
    ;; run the async shell command
    (let ((default-directory "~"))
      (async-shell-command tmtxt/rsync-command "*rsync*"))
    ;;(start-process "rsync" "*rsync*" "rsync" "-arvz" "--progress" src dest)
    ;;(start-process "pwd" "*pwd*" "pwd")
    ;; finally, switch to that window
    (other-window 1)))

(define-key dired-mode-map "Y" 'ora-dired-rsync)

;; Don't warn about "file changed on disk" in /mnt/hgfs

(defun update-buffer-modtime-if-vmware-shared-dir ()
  (when (string-prefix-p "/mnt/hgfs/" buffer-file-name)
    (let ((attributes (file-attributes buffer-file-name)))
      (set-visited-file-modtime (nth 5 attributes))
      t)))

(defun verify-visited-file-modtime--ignore-vmware-shared-dir (original &optional buffer)
  (or (funcall original buffer)
      (with-current-buffer buffer
        (update-buffer-modtime-if-vmware-shared-dir))))
(advice-add 'verify-visited-file-modtime :around #'verify-visited-file-modtime--ignore-vmware-shared-dir)

(defun ask-user-about-supersession-threat--ignore-vmware-shared-dir (original &rest arguments)
  (unless (string-prefix-p "/mnt/hgfs/" buffer-file-name)
    (apply original arguments)))
(advice-add 'ask-user-about-supersession-threat :around #'ask-user-about-supersession-threat--ignore-vmware-shared-dir)

;;; .emacs ends here
(put 'downcase-region 'disabled nil)
(put 'upcase-region 'disabled nil)
(put 'scroll-left 'disabled nil)
(put 'narrow-to-region 'disabled nil)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(inhibit-startup-screen t)
 '(grok-jumps-use-selected-window t)
 '(ido-auto-merge-delay-time 100.0))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
