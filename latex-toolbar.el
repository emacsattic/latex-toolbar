;;; latex-toolbar --- XEmacs LaTeX toolbar

;; Copyright (C) 2002 Triet Hoai Lai
;; Author:     Triet Hoai Lai <thlai@mail.usyd.edu.au>
;; Keywords:   LaTeX, toolbar, symbol
;; Version:    0.4
;; X-URL:      http://ee.usyd.edu.au/~thlai/emacs/
;; X-RCS: $Id: latex-toolbar.el,v 1.11 2002/01/28 12:24:16 thlai Exp $

;; This file is *NOT* part of (X)Emacs.

;; This program is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 2, or (at your option) any later
;; version.

;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
;; more details.

;; You should have received a copy of the GNU General Public License along with
;; GNU Emacs; see the file COPYING.  If not, write to the Free Software
;; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

;;; Commentary:

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Install
;; -------
;;
;; - Put the files in some directory, e.g. ~/elisp/latex-toolbar
;;
;; - Byte compile latex-toolbar.el
;;
;; - Put the following lines into your .emacs
;;      (add-to-list 'load-path "~/elisp/latex-toolbar")
;;      ;; Load AucTeX ...
;;      (require 'tex-site)
;;      ...
;;      (add-hook 'LaTeX-mode-hook
;;                (function (lambda()
;;      		      ;; Add some commands to `TeX-command-list'
;;      		      (add-to-list
;;      		       'TeX-command-list
;;      		       '("PDFLaTeX" "pdflatex '\\nonstopmode\\input{%t}'"
;;      			 TeX-run-command nil nil))
;;      		      (add-to-list
;;      		       'TeX-command-list
;;      		       '("Acroread" "acroread %s.pdf"
;;      			 TeX-run-silent t nil))
;;      		      (add-to-list
;;      		       'TeX-command-list
;;      		       '("xpdf" "xpdf %s.pdf" TeX-run-silent t nil))
;;      		      (add-to-list
;;      		       'TeX-command-list
;;      		       '("gv" "gv %s.ps" TeX-run-silent t nil))
;;      		      ;; ...
;;                            ;; LaTeX toolbar
;;      		      (require 'latex-toolbar)
;;      		      (latex-toolbar-install))))
;;
;; How to add new button:
;; ---------------------
;;
;; There are two types of buttons:
;;	* Buttons are used to insert LaTeX symbols in math mode.
;;	* Buttons do something else, for example inserting a template such as
;;	  table, figure, etc.
;; Currently, there is no second type of button/toolbar.  IMHO, LaTeX symbols
;; are hard to remember all and need some kind of visual feedback.  Menubar
;; already provides an easy way to do other things such as inserting table, etc.
;; However, I am very happy incorporating any improvement.
;;
;; Supposedly, you want to add a button for a symbol with LaTeX command
;; \newsymbol and a button that does newaction, here is the steps:
;;	* Create a pixmap for the first button: the easiest way is using
;;	  `latex2html' available at CTAN.
;;		- Example of tex file to create the button:
;;			\documentclass{article}
;;			\usepackage{???} % package for \newsymbol if it's required.
;;			\begin{document}
;;			\begin{itemize}
;;			 \item newsymbol $\newsymbol{???}$
;;			 ...
;;			\end{itemize}
;;			\end{document}
;;		- You may need to set $MATH_SCALE_FACTOR = 1.6 in ~/.latex2html
;;		  to produce pixmaps of 20x20 size.
;;		- Edit the pixmap with your favorite icon editor (e.g. kiconedi).
;;	* Elisp part:
;;		- If the button is used to insert LaTeX symbol in math mode, you
;;		  should check if `LaTeX-math-<newsymbol>' is already defined
;;		  (Hint: \C-h f will do it interactively).  If not, just add it
;;		  to `latex-toolbar-math-list' (Note: remember to load AucTeX
;;		  first).
;;		- Supposedly, you want to add this button to a new group, say
;;		  `my-misc':
;;		  (defconst latex-toolbar-my-misc-list '("newsymbol" ...))
;;		  (defvar latex-toolbar-my-misc-toolbar nil)
;;		  The sendcond line is used to cache to the toolbar once it is
;;		  created.
;;
;;		- For newaction button, it would be of the form:
;;		  (defconst latex-toolbar-my-misc-list
;;		    '([COMMAND PIXMAP POS-OR-FUNC DOC]
;;		       ...))
;;		  The newaction depends upon the type of POS-OR-FUNC:
;;			+ An integer: insert `\COMMAND{}' and move the point
;;			  forward to this count.
;;			+ `nil': call LaTeX-math-COMMAND.
;;			+ Function or list: will be called when pressing the
;;			  button (i.e. the same as the second element (FUNCTION)
;;			  of toolbar descriptor vector:
;;			  `[GLYPH-LIST FUNCTION ENABLED-P HELP]').
;;		  PIXMAP and DOC are the pixmap file and tooltip respectively.
;;		  Note:
;;		  (defconst latex-toolbar-my-misc-list '("newsymbol" ...))
;;		  is equivalent to:
;;		  (defconst latex-toolbar-my-misc-list
;;		    '(["newsymbol" "newsymbol.xpm" nil "newsymbol"]
;;		       ...))
;;
;; Known bugs:
;; ----------
;;
;;
;; Acknowledgements
;; ----------------
;;
;; A lot of pixmaps are taken from `latex-symbols' package
;; (http://www.math.washington.edu/~palmieri/).  Special thanks to John Palmieri
;; <palmieri@math.washington.edu>, without his package I would not have courage
;; and time to make all the pixmaps.
;;
;; Thanks to Stephan Helma <s.p.helma@gmx.net> for the report of version 0.1
;; doesn't work when the default toolbar position setting is other than `top'.
;;
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; code:



(require 'latex)

(or
 (and (featurep 'xpm)
      (featurep 'toolbar)
      (console-on-window-system-p))
 (error "XEmacs must support xpm, toolbar and running in X-window"))

(defvar latex-toolbar-icon-directory
  (concat
   (cond ((locate-library "latex-toolbar")
	  (concat (file-name-directory (locate-library "latex-toolbar"))))
	 (t
	  (expand-file-name ".")))
   "pic")
  "*The directory where the icon data files are installed.")

(defvar latex-toolbar-math-list
  '(
    (nil "mathring" "Accents")
    (nil "varepsilon" "greek")
    (nil "vartheta" "greek")
    (nil "iota" "greek")
    (nil "xi" "greek")
    (nil "varpi" "greek")
    (nil "varrho" "greek")
    (nil "varsigma" "greek")
    (nil "varphi" "greek")
    (nil "Xi" "greek")
    (nil "notin" "Relational")
    (nil "sqcup" "Binary Op")
    (nil "inoplus" "Binary Op")
    (nil "iff" "Arrows")
    (nil "leadsto" "Arrows")
    (nil "dots" "Misc Symbol")
    (nil "dag" "Non-math")
    (nil "ddag" "Non-math")
    (nil "S" "Non-math")
    (nil "P" "Non-math")
    (nil "copyright" "Non-math")
    (nil "pounds" "Non-math")
    (nil "rightrightarrows" ("AMS" "Arrows"))
    (nil "rightleftarrows" ("AMS" "Arrows"))
    (nil "Rrightarrow" ("AMS" "Arrows"))
    (nil "twoheadrightarrow" ("AMS" "Arrows"))
    (nil "rightarrowtail" ("AMS" "Arrows"))
    (nil "precneqq" ("AMS" "Neg Rel I"))
    (nil "succneqq" ("AMS" "Neg Rel II"))
    (nil "nsubseteqq" ("AMS" "Neg Rel III"))
    (nil "nVdash" ("AMS" "Neg Rel III"))
    )
  "Additional math symbols which are not defined in `LaTeX-math-default'.")

;; Stolen from AucTeX (latex.el)
(let ((math latex-toolbar-math-list)
      (map (lookup-key LaTeX-math-keymap LaTeX-math-abbrev-prefix)))
  (while math
    (let* ((entry (car math))
	   (key (nth 0 entry))
	   value menu name)
      (setq math (cdr math))
      (if (listp (cdr entry))
	  (setq value (nth 1 entry)
		menu (nth 2 entry))
	(setq value (cdr entry)
	      menu nil))
      (if (stringp value)
	  (progn
	   (setq name (intern (concat "LaTeX-math-" value)))
	   (fset name (list 'lambda (list 'arg) (list 'interactive "*P")
			    (list 'LaTeX-math-insert value 'arg))))
	(setq name value))
      (if key
	  (progn 
	    (setq key (if (numberp key) (char-to-string key) (vector key)))
	    (define-key map key name)))
      (if menu
	  (let ((parent LaTeX-math-menu))
	    (if (listp menu)
		(progn 
		  (while (cdr menu)
		    (let ((sub (assoc (car menu) LaTeX-math-menu)))
		      (if sub
			  (setq parent sub)
			(setcdr parent (cons (list (car menu)) (cdr parent))))
		      (setq menu (cdr menu))))
		  (setq menu (car menu))))
	    (let ((sub (assoc menu parent)))
	      (if sub 
		  (if (stringp value)
		      (setcdr sub (cons (vector value name t) (cdr sub)))
		    (error "Cannot have multiple special math menu items"))
		(setcdr parent
			(cons (if (stringp value)
				  (list menu (vector value name t))
				(vector menu name t))
			      (cdr parent))))))))))

(defun latex-toolbar-insert (str cnt)
  (insert str)
  (forward-char cnt))

(defun latex-toolbar-make-button (file)
  (if (not (file-name-extension file))
      (setq file (concat file ".xpm")))
  (setq file (expand-file-name file latex-toolbar-icon-directory))
  (if (file-readable-p file)
      (toolbar-make-button-list file)
    (error "cannot find pixmap %s" file)))


;; Accents
(defconst latex-toolbar-accents-list
  '(
    ;; list element is either a string or vector (see
    ;; `latex-toolbar-install-symbol-toolbar' for details:
    ;; [COMMAND PIXMAP POS DOC]
    ;; - COMMAND: LaTeX command to be inserted
    ;; - PIXMAP: Pixmap file
    ;; - POS: If `nil' then LaTeX-math-<COMMAND> function will be used for
    ;;        toolbar descriptor.
    ;; - DOC: Docstring for the button.
    "hat" "check" "tilde" "acute" "grave" "dot" "ddot" "breve" "bar" "vec"
    ))

(defvar latex-toolbar-accents-toolbar nil)


;; Greek
(defconst latex-toolbar-Greek-letters-list
  '(;; lower case

    "alpha" "beta" "gamma" "delta" "epsilon" "varepsilon" "zeta" "eta" "theta"
    "vartheta" "iota" "kappa" "lambda" "mu" "nu" "xi" "pi" "varpi" "rho"
    "varrho" "sigma" "varsigma" "tau" "upsilon" "phi" "varphi" "chi" "psi"
    "omega"
    ;; upper case
    "Gamma" "Delta" "Theta" "Lambda" "Xi" "Pi" "Sigma" "Upsilon" "Phi" "Psi"
    "Omega"
    ))

;; cache
(defvar latex-toolbar-Greek-letters-toolbar nil)


;; Binary relations
(defconst latex-toolbar-binary-relations-list
  '("le" "ll" "prec" "preceq" "subset" "subseteq"
    ["sqsubset" "sqsubset.xpm" nil "sqsubset (latexsymb package)"]
    "sqsubseteq" "in" "vdash" "mid" "smile" "ge" "gg" "succ" "succeq" "supset"
    "supseteq"
    ["sqsupset" "sqsupset.xpm" nil "sqsupset (latexsymb package)"]
    "sqsupseteq" "ni" "dashv" "parallel" "frown" "notin" "equiv" "doteq" "sim"
    "simeq" "approx" "cong"
    ["Join" "Join.xpm" nil "Join (latexsymb package)"]
     "bowtie" "propto" "models" "perp" "asymp" "neq"
    ))

(defvar latex-toolbar-binary-relations-toolbar nil)


;; Binary operators
(defconst latex-toolbar-binary-operators-list
  '("pm" "cdot" "times" "cup" "sqcup" "vee" "oplus" "odot" "otimes" "bigtriangleup"
    ["lhd" "lhd.xpm" nil "lhd (latexsymb package)"]
    ["unlhd" "unlhd.xpm" nil "unlhd (latexsymb package)"]
    "mp" "div" "setminus" "cap" "sqcap" "wedge" "ominus" "oslash" "bigcirc"
    "bigtriangledown"
    ["rhd" "rhd.xpm" nil "rhd (latexsymb package)"]
    ["unrhd" "unrhd.xpm" nil "unrhd (latexsymb package)"]
    "triangleleft" "triangleright" "star" "ast" "circ" "bullet" "diamond"
    "uplus" "amalg" "dagger" "ddagger" "wr"
    ))
  
(defvar latex-toolbar-binary-operators-toolbar nil)


;; BIG operators
(defconst latex-toolbar-big-operators-list
  '("sum" "prod" "coprod" "int" "bigcup" "bigcap" "bigsqcup" "oint" "bigvee"
    "bigwedge" "bigoplus" "bigotimes" "bigodot" "biguplus"
    ))

(defvar latex-toolbar-big-operators-toolbar nil)



;; Arrows
(defconst latex-toolbar-arrows-list
  '("leftarrow" "rightarrow" "leftrightarrow" "Leftarrow" "Rightarrow"
    "Leftrightarrow" "mapsto" "hookleftarrow" "leftharpoonup" "leftharpoondown"
    "rightleftharpoons" "longleftarrow" "longrightarrow" "longleftrightarrow"
    "Longleftarrow" "Longrightarrow" "Longleftrightarrow" "longmapsto"
    "hookrightarrow" "rightharpoonup" "rightharpoondown" "iff" "uparrow"
    "downarrow" "updownarrow" "Uparrow" "Downarrow" "Updownarrow" "nearrow"
    "searrow" "swarrow" "nwarrow"
    ["leadsto" "leadsto.xpm" nil "leadsto (latexsymb package)"]
    ))

(defvar latex-toolbar-arrows-toolbar nil)



;; Delimiters
(defconst latex-toolbar-delimiters-list
  '("langle" "lfloor" "lceil" "rangle" "rfloor" "rceil" "backslash"
    "uparrow" "updownarrow" "Uparrow" "Downarrow" "Updownarrow"
    ))

(defvar latex-toolbar-delimiters-toolbar nil)



;; Large delimiters
(defconst latex-toolbar-large-delimiters-list
  '("lgroup" "rgroup" "lmoustache" "rmoustache" "arrowvert" "Arrowvert"
    "bracevert"
    ))
(defvar latex-toolbar-large-delimiters-toolbar nil)



;; Misc
(defconst latex-toolbar-misc-symbols-list
  '("dots" "cdots" "vdots" "ddots" "hbar" "imath" "jmath" "ell" "Re" "Im"
    "aleph" "wp" "forall" "exists"
    ["mho" "mho.xpm" nil "mho (latexsymb package)"]
    "partial" "prime" "emptyset" "infty" "nabla" "triangle"
    ["Box" "Box.xpm" nil "Box (latexsymb package)"]
    ["Diamond" "diamondsuit.xpm" nil "Diamond (latexsymb package)"]
    "bot" "top" "angle" "surd" "diamondsuit" "heartsuit" "clubsuit" "spadesuit"
    "neg" "flat" "natural" "sharp"
    ))
(defconst latex-toolbar-misc-symbols-toolbar nil)



;; Non-mathematical symbols
(defconst latex-toolbar-non-math-symbols-list
  '("dag" "ddag" "S" "P" "copyright" "pounds"
    ))
(defvar latex-toolbar-non-math-symbols-toolbar nil)



;; AMS delimiters and Greek and Hebrew
(defconst latex-toolbar-AMS-Greek-Hebrew-delimiters-list
  '( "ulcorner" "urcorner" "llcorner" "lrcorner" "digamma" "varkappa" "beth"
     "daleth" "gimel"
    ))
(defvar latex-toolbar-AMS-Greek-Hebrew-delimiters-toolbar nil)



;; AMS binary relations
;;;
(defconst latex-toolbar-AMS-binary-relations-1-list
  '( "lessdot" "leqslant" "eqslantless" "leqq" "lll" "lesssim" "lessapprox"
     "lessgtr" "lesseqgtr" "lesseqqgtr" "preccurlyeq" "curlyeqprec" "precsim"
     "precapprox" "subseteqq" "Subset" "sqsubset" "therefore" "shortmid"
     "smallsmile" "vartriangleleft" "trianglelefteq"
    ))
(defvar latex-toolbar-AMS-binary-relations-1-toolbar nil)
;;;
(defconst latex-toolbar-AMS-binary-relations-2-list
  '( "gtrdot" "geqslant" "eqslantgtr" "geqq" "ggg" "gtrsim" "gtrapprox"
     "gtrless" "gtreqless" "gtreqqless" "succcurlyeq" "curlyeqsucc" "succsim"
     "succapprox" "supseteqq" "Supset" "sqsupset" "because" "shortparallel"
     "smallfrown" "vartriangleright" "trianglerighteq"
    ))
(defvar latex-toolbar-AMS-binary-relations-2-toolbar nil)
;;;
(defconst latex-toolbar-AMS-binary-relations-3-list
  '( "doteqdot" "risingdotseq" "fallingdotseq" "eqcirc" "circeq" "triangleq"
     "bumpeq" "Bumpeq" "thicksim" "thickapprox" "approxeq" "backsim" "backsimeq"
     "vDash" "Vdash" "Vvdash" "backepsilon" "varpropto" "between" "pitchfork"
     "blacktriangleleft" "blacktriangleright"
    ))
(defvar latex-toolbar-AMS-binary-relations-3-toolbar nil)


;; AMS arrows
(defconst latex-toolbar-AMS-arrows-list
  '( "dashleftarrow" "leftleftarrows" "leftrightarrows" "Lleftarrow"
     "twoheadleftarrow" "leftarrowtail" "leftrightharpoons" "Lsh"
     "looparrowleft" "curvearrowleft" "circlearrowleft" "dashrightarrow"
     "rightrightarrows" "rightleftarrows" "Rrightarrow" "twoheadrightarrow"
     "rightarrowtail" "rightleftharpoons" "Rsh" "looparrowright"
     "curvearrowright" "circlearrowright" "multimap" "upuparrows"
     "downdownarrows" "upharpoonleft" "upharpoonright" "downharpoonleft"
     "downharpoonright" "rightsquigarrow" "leftrightsquigarrow" "nleftarrow"
     "nLeftarrow" "nleftrightarrow" "nLeftrightarrow" "nrightarrow" "nRightarrow"
    ))
(defvar latex-toolbar-AMS-arrows-toolbar nil)



;; AMS negated binary relations and arrows
(defconst latex-toolbar-AMS-negated-binary-relations-arrows-1-list
  '("nless" "lneq" "nleq" "nleqslant" "lneqq" "lvertneqq" "nleqq" "lnsim"
    "lnapprox" "nprec" "npreceq" "precneqq" "precnsim" "precnapprox" "subsetneq"
    "varsubsetneq" "nsubseteq" "subsetneqq" "nleftarrow" "nLeftarrow"
    ))
(defvar latex-toolbar-AMS-negated-binary-relations-arrows-1-toolbar nil)

;;;
(defconst latex-toolbar-AMS-negated-binary-relations-arrows-2-list
  '("ngtr" "gneq" "ngeq" "ngeqslant" "gneqq" "gvertneqq" "ngeqq" "gnsim"
    "gnapprox" "nsucc" "nsucceq" "succneqq" "succnsim" "succnapprox" "supsetneq"
    "varsupsetneq" "nsupseteq" "supsetneqq" "nrightarrow" "nRightarrow"
    ))
(defvar latex-toolbar-AMS-negated-binary-relations-arrows-2-toolbar nil)

;;;
(defconst latex-toolbar-AMS-negated-binary-relations-arrows-3-list
  '( "varsubsetneqq" "varsupsetneqq" "nsubseteqq" "nsupseteqq" "nmid"
     "nparallel" "nshortmid" "nshortparallel" "nsim" "ncong" "nvdash" "nvDash"
     "nVdash" "nVDash" "ntriangleleft" "ntriangleright" "ntrianglelefteq"
     "ntrianglerighteq" "nleftrightarrow" "nLeftrightarrow"
     ))
(defvar latex-toolbar-AMS-negated-binary-relations-arrows-3-toolbar nil)


;; AMS Binary Operators.
(defconst latex-toolbar-AMS-binary-operators-list
  '("dotplus" "ltimes" "Cup" "veebar" "boxplus" "boxtimes" "leftthreetimes"
    "curlyvee" "centerdot" "rtimes" "Cap" "barwedge" "boxminus" "boxdot"
    "rightthreetimes" "curlywedge" "intercal" "divideontimes" "smallsetminus"
    "doublebarwedge" "circleddash" "circledcirc" "circledast"
    ))
(defvar latex-toolbar-AMS-binary-operators-toolbar nil)


;; AMS Miscellaneous.
(defconst latex-toolbar-AMS-misc-list
  '("hbar" "square" "vartriangle" "triangledown" "lozenge" "angle" "diagup"
    "nexists" "eth" "hslash" "blacksquare" "blacktriangle" "blacktriangledown"
    "blacklozenge" "measuredangle" "diagdown" "Finv" "mho" "Bbbk" "circledS"
    "complement" "Game" "bigstar" "sphericalangle" "backprime" "varnothing"
    ))
(defvar latex-toolbar-AMS-misc-toolbar nil)


;; Math Alphabets.
(defconst latex-toolbar-math-alphabets-list
  '(["mathrm" "mathrm.xpm" -1 "mathrm"]
    ["mathit" "mathit.xpm" -1 "mathit"]
    ["mathnormal" "mathnormal.xpm" -1 "mathnormal"]
    ["mathcal" "mathcal.xpm" -1 "mathcal"]
    ["mathfrak" "mathfrak.xpm" -1 "mathfrak (eufrak package)"]
    ["mathbb" "mathbb.xpm" -1 "mathbb (amsfonts or amssymb package)"]
    ))
(defvar latex-toolbar-math-alphabets-toolbar nil)


;; Math construct
(defconst latex-toolbar-math-constructs-list
  '("widetilde" "overleftarrow" "overbrace" "widehat" "overrightarrow"
    "underline" "underbrace"
    ["sqrt" "sqrt.xpm" -1 "sqrt"]
    ["sqrt" "sqrtn.xpm" nil "sqrt[n]"]
    "frac"
    ))
(defvar latex-toolbar-math-constructs-toolbar nil)


;;; LaTeX symbol toolbar

(defconst latex-toolbar-accents-icon
  (latex-toolbar-make-button "TBaccent.xpm"))

(defconst latex-toolbar-Greek-letters-icon
  (latex-toolbar-make-button "TBgreek.xpm"))

(defconst latex-toolbar-binary-relations-icon
  (latex-toolbar-make-button "TBrel.xpm"))

(defconst latex-toolbar-binary-operators-icon
  (latex-toolbar-make-button "TBop.xpm"))

(defconst latex-toolbar-big-operators-icon
  (latex-toolbar-make-button "TBbop.xpm"))

(defconst latex-toolbar-arrows-icon
  (latex-toolbar-make-button "TBarrow.xpm"))

(defconst latex-toolbar-delimiters-icon
  (latex-toolbar-make-button "TBdelim.xpm"))

(defconst latex-toolbar-large-delimiters-icon
  (latex-toolbar-make-button "TBldelim.xpm"))

(defconst latex-toolbar-misc-symbols-icon
  (latex-toolbar-make-button "TBmisc.xpm"))

(defconst latex-toolbar-non-math-symbols-icon
  (latex-toolbar-make-button "TBnonmath.xpm"))

(defconst latex-toolbar-AMS-Greek-Hebrew-delimiters-icon
  (latex-toolbar-make-button "TBAMSdelim.xpm"))

(defconst latex-toolbar-AMS-binary-relations-icon-1
  (latex-toolbar-make-button "TBAMSrel-1.xpm"))

(defconst latex-toolbar-AMS-binary-relations-icon-2
  (latex-toolbar-make-button "TBAMSrel-2.xpm"))

(defconst latex-toolbar-AMS-binary-relations-icon-3
  (latex-toolbar-make-button "TBAMSrel-3.xpm"))

(defconst latex-toolbar-AMS-arrows-icon
  (latex-toolbar-make-button "TBAMSarrow.xpm"))

(defconst latex-toolbar-AMS-negated-binary-relations-icon-1
  (latex-toolbar-make-button "TBAMSnrel-1.xpm"))

(defconst latex-toolbar-AMS-negated-binary-relations-icon-2
  (latex-toolbar-make-button "TBAMSnrel-2.xpm"))

(defconst latex-toolbar-AMS-negated-binary-relations-icon-3
  (latex-toolbar-make-button "TBAMSnrel-3.xpm"))

(defconst latex-toolbar-AMS-binary-operators-icon
  (latex-toolbar-make-button "TBAMSop.xpm"))

(defconst latex-toolbar-AMS-misc-icon
  (latex-toolbar-make-button "TBAMSmisc.xpm"))

(defconst latex-toolbar-math-alphabets-icon
  (latex-toolbar-make-button "TBmathalph.xpm"))

(defconst latex-toolbar-math-construct-icon
  (latex-toolbar-make-button "TBmathconst.xpm"))

;;
(defvar latex-toolbar-symbol-toolbar-position
  (cond ((eq (default-toolbar-position) 'bottom)
	 'top)
	(t 'bottom))
  "Don't set it, use `latex-toolbar-set-position' instead.")

(defvar latex-toolbar-symbol-toolbar-spec nil)
(defvar latex-toolbar-symbol-toolbar-height nil)
(defvar latex-toolbar-symbol-toolbar-width nil)
(defvar latex-toolbar-symbol-toolbar-visible-p nil)
(defvar latex-toolbar-symbol-current-toolbar-name nil)

(defun latex-toolbar-symbol-toolbar-set-position (&optional position force-p)
  "Set position of symbol toolbar.
Valid positions are \`top\', \`bottom\', \`left\' or \`right\'.  However, it
should NOT be the same with the `default-toolbar' position."
  (let ((oldpos latex-toolbar-symbol-toolbar-position)
	(completion '(("top") ("bottom") ("left") ("right")))
	pos toolbar-name)
    (setq completion (delete (list (symbol-name (default-toolbar-position)))
			     completion))
    (or position
	(setq position
	      (completing-read "Position: "
			       completion nil t)))
    (unless (string= position "")
      (setq pos (intern position))
      (unless (and (not force-p) (eq oldpos pos))
	(if (eq pos (default-toolbar-position))
	    (error "symbol toolbar position the same as default toolbar position")
	  (setq toolbar-name latex-toolbar-symbol-current-toolbar-name)
	  (if toolbar-name
	      (latex-toolbar-uninstall-symbol-toolbar)))
	(cond ((eq pos 'top)
	       (setq latex-toolbar-symbol-toolbar-spec top-toolbar)
	       (setq latex-toolbar-symbol-toolbar-height top-toolbar-height)
	       (setq latex-toolbar-symbol-toolbar-visible-p top-toolbar-visible-p))
	      ((eq pos 'bottom)
	       (setq latex-toolbar-symbol-toolbar-spec bottom-toolbar)
	       (setq latex-toolbar-symbol-toolbar-height bottom-toolbar-height)
	       (setq latex-toolbar-symbol-toolbar-visible-p bottom-toolbar-visible-p))
	      ((eq pos 'left)
	       (setq latex-toolbar-symbol-toolbar-spec left-toolbar)
	       (setq latex-toolbar-symbol-toolbar-width left-toolbar-width)
	       (setq latex-toolbar-symbol-toolbar-visible-p left-toolbar-visible-p))
	      ((eq pos 'right)
	       (setq latex-toolbar-symbol-toolbar-spec right-toolbar)
	       (setq latex-toolbar-symbol-toolbar-width right-toolbar-width)
	       (setq latex-toolbar-symbol-toolbar-visible-p right-toolbar-visible-p)))
	(setq latex-toolbar-symbol-toolbar-position pos)
	(if toolbar-name
	    (latex-toolbar-install-symbol-toolbar toolbar-name))
	))
    ))

(latex-toolbar-symbol-toolbar-set-position
 (symbol-name latex-toolbar-symbol-toolbar-position) t)

(defun latex-toolbar-set-position (&optional position)
  (interactive)
  (latex-toolbar-symbol-toolbar-set-position position))

(defun latex-toolbar-install-default-toolbar (toolbar)
  (set-specifier default-toolbar (cons (current-buffer) toolbar))
  (set-specifier default-toolbar-visible-p (cons (current-buffer) t)))

(defun latex-toolbar-install-symbol-toolbar (toolbar-name)
  (let ((toolbar (symbol-value (intern (concat
					"latex-toolbar-"
					toolbar-name
					"-toolbar"))))
	symbols)
    (unless toolbar
      (setq symbols (symbol-value (intern (concat
					   "latex-toolbar-"
					   toolbar-name
					   "-list"))))
      (dolist (sym symbols)
	(let (func cmd icon pos doc button key)
	  (cond ((stringp sym)
		 (setq func (intern-soft (concat "LaTeX-math-" sym)))
		 (if func
		     (setq cmd func)
		   (setq cmd (list 'latex-toolbar-insert
				   (format "\\%s{}" sym) -1)))
		 (setq icon (latex-toolbar-make-button sym))
		 (setq key (where-is-internal func LaTeX-math-keymap t))
		 (if key
		     (setq doc (format "%s (math-mode: %s)" sym key))
		   (setq doc sym)))
		((vectorp sym)
		  (setq pos (elt sym 2))
		  (cond ((integerp pos)
			 (setq cmd (list 'latex-toolbar-insert
					 (format "\\%s{}" (elt sym 0))
					 pos)))
			((null pos)
			 (setq func (intern-soft (concat "LaTeX-math-" (elt sym 0))))
			 (if func
			     (setq cmd func)
			   (setq cmd (list 'latex-toolbar-insert
					   (format "\\%s{}" (elt sym 0))
					   -1))))
			((or (functionp pos) (listp pos))
			 (setq cmd pos))
			(t
			 (error "wrong type of POS")
			 ))
		  (setq icon (latex-toolbar-make-button (elt sym 1)))
		  (setq key (where-is-internal func LaTeX-math-keymap t))
		  (if key
		      (setq doc (format "%s (math-mode: %s)" (elt sym 3) key))
		    (setq doc (elt sym 3))))
		(t
		 (error "wrong type of symbol descriptor")))
	  (setq button (vector icon cmd t doc))
	  (push button toolbar)
	  ))
      (setq toolbar (nreverse toolbar))
      (set (intern (concat "latex-toolbar-" toolbar-name "-toolbar"))
		  toolbar)
      )
    (set-specifier latex-toolbar-symbol-toolbar-spec
		   (cons (current-buffer) toolbar))
    (cond ((or (eq latex-toolbar-symbol-toolbar-position 
		   'top)
	       (eq latex-toolbar-symbol-toolbar-position
		   'bottom))
	   (set-specifier latex-toolbar-symbol-toolbar-height
			  (cons (current-buffer) 25)))
	  (t
	   (set-specifier latex-toolbar-symbol-toolbar-width
			  (cons (current-buffer) 25))))
    (set-specifier latex-toolbar-symbol-toolbar-visible-p
		   (cons (current-buffer) t))
    (setq latex-toolbar-symbol-current-toolbar-name toolbar-name)
    ))

(defun latex-toolbar-uninstall-symbol-toolbar ()
  (remove-specifier latex-toolbar-symbol-toolbar-spec
		    (current-buffer))
  (cond ((or (eq latex-toolbar-symbol-toolbar-position 
		 'top)
	     (eq latex-toolbar-symbol-toolbar-position
		 'bottom))
	 (set-specifier latex-toolbar-symbol-toolbar-height
			(cons (current-buffer) 0)))
	(t
	 (set-specifier latex-toolbar-symbol-toolbar-width
			(cons (current-buffer) 0))))
  (set-specifier latex-toolbar-symbol-toolbar-visible-p
		 (cons (current-buffer) nil))
  (setq latex-toolbar-symbol-current-toolbar-name nil)
  )

(defconst latex-toolbar-remove-icon
  (latex-toolbar-make-button "TBrem.xpm"))

(defconst latex-toolbar-back-icon
  (latex-toolbar-make-button "TBback.xpm"))

(defconst latex-toolbar-symbol-toolbar
  '(
    [latex-toolbar-back-icon
     (latex-toolbar-install-default-toolbar latex-toolbar)
     t "Back to LaTeX toolbar"]
    ;;
    [latex-toolbar-accents-icon
     (latex-toolbar-install-symbol-toolbar "accents") t "Accents"]
    [latex-toolbar-Greek-letters-icon
     (latex-toolbar-install-symbol-toolbar "Greek-letters") t "Greek letters"]
    [latex-toolbar-binary-relations-icon
     (latex-toolbar-install-symbol-toolbar "binary-relations") t "Binary relations"]
    [latex-toolbar-binary-operators-icon
     (latex-toolbar-install-symbol-toolbar "binary-operators") t "Binary operators"]
    [latex-toolbar-big-operators-icon
     (latex-toolbar-install-symbol-toolbar "big-operators") t "Big operators"]
    [latex-toolbar-arrows-icon
     (latex-toolbar-install-symbol-toolbar "arrows") t "Arrows"]
    [latex-toolbar-delimiters-icon
     (latex-toolbar-install-symbol-toolbar "delimiters") t "Delimiters"]
    [latex-toolbar-large-delimiters-icon
     (latex-toolbar-install-symbol-toolbar "large-delimiters") t "Large delimiters"]
    [latex-toolbar-misc-symbols-icon
     (latex-toolbar-install-symbol-toolbar "misc-symbols") t "Misc symbols"]
    [latex-toolbar-non-math-symbols-icon
     (latex-toolbar-install-symbol-toolbar "non-math-symbols") t "Non-math symbols"]
    [latex-toolbar-AMS-Greek-Hebrew-delimiters-icon
     (latex-toolbar-install-symbol-toolbar "AMS-Greek-Hebrew-delimiters")
     t "AMS Greek and Hebrew letters, and delimiters"]
    [latex-toolbar-AMS-binary-relations-icon-1
     (latex-toolbar-install-symbol-toolbar "AMS-binary-relations-1")
     t "AMS binary relations No. 1"]
    [latex-toolbar-AMS-binary-relations-icon-2
     (latex-toolbar-install-symbol-toolbar "AMS-binary-relations-2")
     t "AMS binary relations No. 2"]
    [latex-toolbar-AMS-binary-relations-icon-3
     (latex-toolbar-install-symbol-toolbar "AMS-binary-relations-3")
     t "AMS binary relations No. 3"]
    [latex-toolbar-AMS-arrows-icon
     (latex-toolbar-install-symbol-toolbar "AMS-arrows") t "AMS arrows"]
    [latex-toolbar-AMS-negated-binary-relations-icon-1
     (latex-toolbar-install-symbol-toolbar "AMS-negated-binary-relations-arrows-1")
     t "AMS negated binary relations No. 1"]
    [latex-toolbar-AMS-negated-binary-relations-icon-2
     (latex-toolbar-install-symbol-toolbar "AMS-negated-binary-relations-arrows-2")
     t "AMS negated binary relations No. 2"]
    [latex-toolbar-AMS-negated-binary-relations-icon-3
     (latex-toolbar-install-symbol-toolbar "AMS-negated-binary-relations-arrows-3")
     t "AMS negated binary relations No. 3"]
    [latex-toolbar-AMS-binary-operators-icon
     (latex-toolbar-install-symbol-toolbar "AMS-binary-operators")
     t "AMS binary operators"]
    [latex-toolbar-AMS-misc-icon
     (latex-toolbar-install-symbol-toolbar "AMS-misc") t "AMS misc symbols"]
    [latex-toolbar-math-alphabets-icon
     (latex-toolbar-install-symbol-toolbar "math-alphabets") t "Math alphabets"]
    [latex-toolbar-math-construct-icon
     (latex-toolbar-install-symbol-toolbar "math-constructs") t "Math constructs"]
    nil
    [latex-toolbar-remove-icon latex-toolbar-uninstall-symbol-toolbar
			       t "Remove symbol toolbar"]
    )
  "LaTeX symbol toolbar")

(defconst latex-toolbar-latex-icon
  (latex-toolbar-make-button "TBlatex.xpm"))

(defconst latex-toolbar-pdflatex-icon
  (latex-toolbar-make-button "TBpdflatex.xpm"))

(defconst latex-toolbar-bibtex-icon
  (latex-toolbar-make-button "TBbibtex.xpm"))

(defconst latex-toolbar-xdvi-icon
  (latex-toolbar-make-button "TBxdvi.xpm"))

(defconst latex-toolbar-gv-icon
  (latex-toolbar-make-button "TBgv.xpm"))

(defconst latex-toolbar-xpdf-icon
  (latex-toolbar-make-button "TBxpdf.xpm"))

(defconst latex-toolbar-acroread-icon
  (latex-toolbar-make-button "TBacroread.xpm"))

(defconst latex-toolbar-symbol-icon
  (latex-toolbar-make-button "TBsymbol.xpm"))

(defconst latex-toolbar-math-mode-icon
  (latex-toolbar-make-button "TBmath.xpm"))

(defconst latex-toolbar-help-icon
  (latex-toolbar-make-button "TBhelp.xpm"))


(defconst latex-toolbar
  '([toolbar-file-icon          find-file       t       "Open a file"   ]
    [toolbar-folder-icon        dired           t       "View directory"]
    [toolbar-disk-icon          save-buffer     t       "Save buffer"   ]
    [toolbar-cut-icon           x-kill-primary-selection t "Kill region"]
    [toolbar-copy-icon          x-copy-primary-selection t "Copy region"]
    [toolbar-paste-icon         x-yank-clipboard-selection t "Paste from clipboard"]
    [toolbar-undo-icon          undo            t       "Undo edit"     ]
    [toolbar-spell-icon         toolbar-ispell  t       "Spellcheck"    ]
    [toolbar-replace-icon       query-replace   t       "Replace text"  ]

    [latex-toolbar-latex-icon   (TeX-command-menu "LaTeX")
				t "Run LaTeX"]
    [latex-toolbar-bibtex-icon  (TeX-command-menu "BibTeX")
				t "Run BibTeX"]
    [latex-toolbar-pdflatex-icon (TeX-command-menu "PDFLaTeX")
				 t "Run PDFLaTeX"]
    [latex-toolbar-xdvi-icon    (TeX-command-menu "xdvi")
				t "Run Xdvi"]
    [latex-toolbar-gv-icon      (TeX-command-menu "gv")
				t "Run Gv"]
    [latex-toolbar-xpdf-icon    (TeX-command-menu "xpdf")
				t "Run Xpdf"]
    [latex-toolbar-acroread-icon (TeX-command-menu "Acroread")
				 t "Run Acrobat Reader"]
    [latex-toolbar-math-mode-icon LaTeX-math-mode
				  t "Toggle math mode"]
    [latex-toolbar-symbol-icon (latex-toolbar-install-default-toolbar
				latex-toolbar-symbol-toolbar)
     t "Display LaTeX symbol toolbar"]
    [latex-toolbar-remove-icon latex-toolbar-uninstall-symbol-toolbar
			       t "Remove symbol toolbar"]
    ;;
    nil
    [latex-toolbar-help-icon              (info "auctex")    t   "AucTeX help"]
    )
  "The toolbar used in LaTeX mode.")

(defun latex-toolbar-install ()
  (interactive)
  (set-specifier default-toolbar (cons (current-buffer) latex-toolbar)))

(provide 'latex-toolbar)

;; latex-toolbar.el ends here