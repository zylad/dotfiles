" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
plugin/cecutil.vim	[[[1
536
" cecutil.vim : save/restore window position
"               save/restore mark position
"               save/restore selected user maps
"  Author:	Charles E. Campbell, Jr.
"  Version:	18h	ASTRO-ONLY
"  Date:	Apr 05, 2010
"
"  Saving Restoring Destroying Marks: {{{1
"       call SaveMark(markname)       let savemark= SaveMark(markname)
"       call RestoreMark(markname)    call RestoreMark(savemark)
"       call DestroyMark(markname)
"       commands: SM RM DM
"
"  Saving Restoring Destroying Window Position: {{{1
"       call SaveWinPosn()        let winposn= SaveWinPosn()
"       call RestoreWinPosn()     call RestoreWinPosn(winposn)
"		\swp : save current window/buffer's position
"		\rwp : restore current window/buffer's previous position
"       commands: SWP RWP
"
"  Saving And Restoring User Maps: {{{1
"       call SaveUserMaps(mapmode,maplead,mapchx,suffix)
"       call RestoreUserMaps(suffix)
"
" GetLatestVimScripts: 1066 1 :AutoInstall: cecutil.vim
"
" You believe that God is one. You do well. The demons also {{{1
" believe, and shudder. But do you want to know, vain man, that
" faith apart from works is dead?  (James 2:19,20 WEB)
"redraw!|call inputsave()|call input("Press <cr> to continue")|call inputrestore()

" ---------------------------------------------------------------------
" Load Once: {{{1
if &cp || exists("g:loaded_cecutil")
 finish
endif
let g:loaded_cecutil = "v18h"
let s:keepcpo        = &cpo
set cpo&vim
"DechoRemOn

" =======================
"  Public Interface: {{{1
" =======================

" ---------------------------------------------------------------------
"  Map Interface: {{{2
if !hasmapto('<Plug>SaveWinPosn')
 map <unique> <Leader>swp <Plug>SaveWinPosn
endif
if !hasmapto('<Plug>RestoreWinPosn')
 map <unique> <Leader>rwp <Plug>RestoreWinPosn
endif
nmap <silent> <Plug>SaveWinPosn		:call SaveWinPosn()<CR>
nmap <silent> <Plug>RestoreWinPosn	:call RestoreWinPosn()<CR>

" ---------------------------------------------------------------------
" Command Interface: {{{2
com! -bar -nargs=0 SWP	call SaveWinPosn()
com! -bar -nargs=? RWP	call RestoreWinPosn(<args>)
com! -bar -nargs=1 SM	call SaveMark(<q-args>)
com! -bar -nargs=1 RM	call RestoreMark(<q-args>)
com! -bar -nargs=1 DM	call DestroyMark(<q-args>)

com! -bar -nargs=1 WLR	call s:WinLineRestore(<q-args>)

if v:version < 630
 let s:modifier= "sil! "
else
 let s:modifier= "sil! keepj "
endif

" ===============
" Functions: {{{1
" ===============

" ---------------------------------------------------------------------
" SaveWinPosn: {{{2
"    let winposn= SaveWinPosn()  will save window position in winposn variable
"    call SaveWinPosn()          will save window position in b:cecutil_winposn{b:cecutil_iwinposn}
"    let winposn= SaveWinPosn(0) will *only* save window position in winposn variable (no stacking done)
fun! SaveWinPosn(...)
"  echomsg "Decho: SaveWinPosn() a:0=".a:0
  if line("$") == 1 && getline(1) == ""
"   echomsg "Decho: SaveWinPosn : empty buffer"
   return ""
  endif
  let so_keep   = &l:so
  let siso_keep = &siso
  let ss_keep   = &l:ss
  setlocal so=0 siso=0 ss=0

  let swline = line(".")                           " save-window line in file
  let swcol  = col(".")                            " save-window column in file
  if swcol >= col("$")
   let swcol= swcol + virtcol(".") - virtcol("$")  " adjust for virtual edit (cursor past end-of-line)
  endif
  let swwline   = winline() - 1                    " save-window window line
  let swwcol    = virtcol(".") - wincol()          " save-window window column
  let savedposn = ""
"  echomsg "Decho: sw[".swline.",".swcol."] sww[".swwline.",".swwcol."]"
  let savedposn = "call GoWinbufnr(".winbufnr(0).")"
  let savedposn = savedposn."|".s:modifier.swline
  let savedposn = savedposn."|".s:modifier."norm! 0z\<cr>"
  if swwline > 0
   let savedposn= savedposn.":".s:modifier."call s:WinLineRestore(".(swwline+1).")\<cr>"
  endif
  if swwcol > 0
   let savedposn= savedposn.":".s:modifier."norm! 0".swwcol."zl\<cr>"
  endif
  let savedposn = savedposn.":".s:modifier."call cursor(".swline.",".swcol.")\<cr>"

  " save window position in
  " b:cecutil_winposn_{iwinposn} (stack)
  " only when SaveWinPosn() is used
  if a:0 == 0
   if !exists("b:cecutil_iwinposn")
	let b:cecutil_iwinposn= 1
   else
	let b:cecutil_iwinposn= b:cecutil_iwinposn + 1
   endif
"   echomsg "Decho: saving posn to SWP stack"
   let b:cecutil_winposn{b:cecutil_iwinposn}= savedposn
  endif

  let &l:so = so_keep
  let &siso = siso_keep
  let &l:ss = ss_keep

"  if exists("b:cecutil_iwinposn")                                                                  " Decho
"   echomsg "Decho: b:cecutil_winpos{".b:cecutil_iwinposn."}[".b:cecutil_winposn{b:cecutil_iwinposn}."]"
"  else                                                                                             " Decho
"   echomsg "Decho: b:cecutil_iwinposn doesn't exist"
"  endif                                                                                            " Decho
"  echomsg "Decho: SaveWinPosn [".savedposn."]"
  return savedposn
endfun

" ---------------------------------------------------------------------
" RestoreWinPosn: {{{2
"      call RestoreWinPosn()
"      call RestoreWinPosn(winposn)
fun! RestoreWinPosn(...)
"  echomsg "Decho: RestoreWinPosn() a:0=".a:0
"  echomsg "Decho: getline(1)<".getline(1).">"
"  echomsg "Decho: line(.)=".line(".")
  if line("$") == 1 && getline(1) == ""
"   echomsg "Decho: RestoreWinPosn : empty buffer"
   return ""
  endif
  let so_keep   = &l:so
  let siso_keep = &l:siso
  let ss_keep   = &l:ss
  setlocal so=0 siso=0 ss=0

  if a:0 == 0 || a:1 == ""
   " use saved window position in b:cecutil_winposn{b:cecutil_iwinposn} if it exists
   if exists("b:cecutil_iwinposn") && exists("b:cecutil_winposn{b:cecutil_iwinposn}")
"    echomsg "Decho: using stack b:cecutil_winposn{".b:cecutil_iwinposn."}<".b:cecutil_winposn{b:cecutil_iwinposn}.">"
	try
	 exe s:modifier.b:cecutil_winposn{b:cecutil_iwinposn}
	catch /^Vim\%((\a\+)\)\=:E749/
	 " ignore empty buffer error messages
	endtry
	" normally drop top-of-stack by one
	" but while new top-of-stack doesn't exist
	" drop top-of-stack index by one again
	if b:cecutil_iwinposn >= 1
	 unlet b:cecutil_winposn{b:cecutil_iwinposn}
	 let b:cecutil_iwinposn= b:cecutil_iwinposn - 1
	 while b:cecutil_iwinposn >= 1 && !exists("b:cecutil_winposn{b:cecutil_iwinposn}")
	  let b:cecutil_iwinposn= b:cecutil_iwinposn - 1
	 endwhile
	 if b:cecutil_iwinposn < 1
	  unlet b:cecutil_iwinposn
	 endif
	endif
   else
	echohl WarningMsg
	echomsg "***warning*** need to SaveWinPosn first!"
	echohl None
   endif

  else	 " handle input argument
"   echomsg "Decho: using input a:1<".a:1.">"
   " use window position passed to this function
   exe a:1
   " remove a:1 pattern from b:cecutil_winposn{b:cecutil_iwinposn} stack
   if exists("b:cecutil_iwinposn")
	let jwinposn= b:cecutil_iwinposn
	while jwinposn >= 1                     " search for a:1 in iwinposn..1
	 if exists("b:cecutil_winposn{jwinposn}")    " if it exists
	  if a:1 == b:cecutil_winposn{jwinposn}      " and the pattern matches
	   unlet b:cecutil_winposn{jwinposn}            " unlet it
	   if jwinposn == b:cecutil_iwinposn            " if at top-of-stack
		let b:cecutil_iwinposn= b:cecutil_iwinposn - 1      " drop stacktop by one
	   endif
	  endif
	 endif
	 let jwinposn= jwinposn - 1
	endwhile
   endif
  endif

  " Seems to be something odd: vertical motions after RWP
  " cause jump to first column.  The following fixes that.
  " Note: was using wincol()>1, but with signs, a cursor
  " at column 1 yields wincol()==3.  Beeping ensued.
  let vekeep= &ve
  set ve=all
  if virtcol('.') > 1
   exe s:modifier."norm! hl"
  elseif virtcol(".") < virtcol("$")
   exe s:modifier."norm! lh"
  endif
  let &ve= vekeep

  let &l:so   = so_keep
  let &l:siso = siso_keep
  let &l:ss   = ss_keep

"  echomsg "Decho: RestoreWinPosn"
endfun

" ---------------------------------------------------------------------
" s:WinLineRestore: {{{2
fun! s:WinLineRestore(swwline)
"  echomsg "Decho: s:WinLineRestore(swwline=".a:swwline.")"
  while winline() < a:swwline
   let curwinline= winline()
   exe s:modifier."norm! \<c-y>"
   if curwinline == winline()
	break
   endif
  endwhile
"  echomsg "Decho: s:WinLineRestore"
endfun

" ---------------------------------------------------------------------
" GoWinbufnr: go to window holding given buffer (by number) {{{2
"   Prefers current window; if its buffer number doesn't match,
"   then will try from topleft to bottom right
fun! GoWinbufnr(bufnum)
"  call Dfunc("GoWinbufnr(".a:bufnum.")")
  if winbufnr(0) == a:bufnum
"   call Dret("GoWinbufnr : winbufnr(0)==a:bufnum")
   return
  endif
  winc t
  let first=1
  while winbufnr(0) != a:bufnum && (first || winnr() != 1)
  	winc w
	let first= 0
   endwhile
"  call Dret("GoWinbufnr")
endfun

" ---------------------------------------------------------------------
" SaveMark: sets up a string saving a mark position. {{{2
"           For example, SaveMark("a")
"           Also sets up a global variable, g:savemark_{markname}
fun! SaveMark(markname)
"  call Dfunc("SaveMark(markname<".a:markname.">)")
  let markname= a:markname
  if strpart(markname,0,1) !~ '\a'
   let markname= strpart(markname,1,1)
  endif
"  call Decho("markname=".markname)

  let lzkeep  = &lz
  set lz

  if 1 <= line("'".markname) && line("'".markname) <= line("$")
   let winposn               = SaveWinPosn(0)
   exe s:modifier."norm! `".markname
   let savemark              = SaveWinPosn(0)
   let g:savemark_{markname} = savemark
   let savemark              = markname.savemark
   call RestoreWinPosn(winposn)
  else
   let g:savemark_{markname} = ""
   let savemark              = ""
  endif

  let &lz= lzkeep

"  call Dret("SaveMark : savemark<".savemark.">")
  return savemark
endfun

" ---------------------------------------------------------------------
" RestoreMark: {{{2
"   call RestoreMark("a")  -or- call RestoreMark(savemark)
fun! RestoreMark(markname)
"  call Dfunc("RestoreMark(markname<".a:markname.">)")

  if strlen(a:markname) <= 0
"   call Dret("RestoreMark : no such mark")
   return
  endif
  let markname= strpart(a:markname,0,1)
  if markname !~ '\a'
   " handles 'a -> a styles
   let markname= strpart(a:markname,1,1)
  endif
"  call Decho("markname=".markname." strlen(a:markname)=".strlen(a:markname))

  let lzkeep  = &lz
  set lz
  let winposn = SaveWinPosn(0)

  if strlen(a:markname) <= 2
   if exists("g:savemark_{markname}") && strlen(g:savemark_{markname}) != 0
	" use global variable g:savemark_{markname}
"	call Decho("use savemark list")
	call RestoreWinPosn(g:savemark_{markname})
	exe "norm! m".markname
   endif
  else
   " markname is a savemark command (string)
"	call Decho("use savemark command")
   let markcmd= strpart(a:markname,1)
   call RestoreWinPosn(markcmd)
   exe "norm! m".markname
  endif

  call RestoreWinPosn(winposn)
  let &lz       = lzkeep

"  call Dret("RestoreMark")
endfun

" ---------------------------------------------------------------------
" DestroyMark: {{{2
"   call DestroyMark("a")  -- destroys mark
fun! DestroyMark(markname)
"  call Dfunc("DestroyMark(markname<".a:markname.">)")

  " save options and set to standard values
  let reportkeep= &report
  let lzkeep    = &lz
  set lz report=10000

  let markname= strpart(a:markname,0,1)
  if markname !~ '\a'
   " handles 'a -> a styles
   let markname= strpart(a:markname,1,1)
  endif
"  call Decho("markname=".markname)

  let curmod  = &mod
  let winposn = SaveWinPosn(0)
  1
  let lineone = getline(".")
  exe "k".markname
  d
  put! =lineone
  let &mod    = curmod
  call RestoreWinPosn(winposn)

  " restore options to user settings
  let &report = reportkeep
  let &lz     = lzkeep

"  call Dret("DestroyMark")
endfun

" ---------------------------------------------------------------------
" QArgSplitter: to avoid \ processing by <f-args>, <q-args> is needed. {{{2
" However, <q-args> doesn't split at all, so this one returns a list
" with splits at all whitespace (only!), plus a leading length-of-list.
" The resulting list:  qarglist[0] corresponds to a:0
"                      qarglist[i] corresponds to a:{i}
fun! QArgSplitter(qarg)
"  call Dfunc("QArgSplitter(qarg<".a:qarg.">)")
  let qarglist    = split(a:qarg)
  let qarglistlen = len(qarglist)
  let qarglist    = insert(qarglist,qarglistlen)
"  call Dret("QArgSplitter ".string(qarglist))
  return qarglist
endfun

" ---------------------------------------------------------------------
" ListWinPosn: {{{2
"fun! ListWinPosn()                                                        " Decho 
"  if !exists("b:cecutil_iwinposn") || b:cecutil_iwinposn == 0             " Decho 
"   call Decho("nothing on SWP stack")                                     " Decho
"  else                                                                    " Decho
"   let jwinposn= b:cecutil_iwinposn                                       " Decho 
"   while jwinposn >= 1                                                    " Decho 
"    if exists("b:cecutil_winposn{jwinposn}")                              " Decho 
"     call Decho("winposn{".jwinposn."}<".b:cecutil_winposn{jwinposn}.">") " Decho 
"    else                                                                  " Decho 
"     call Decho("winposn{".jwinposn."} -- doesn't exist")                 " Decho 
"    endif                                                                 " Decho 
"    let jwinposn= jwinposn - 1                                            " Decho 
"   endwhile                                                               " Decho 
"  endif                                                                   " Decho
"endfun                                                                    " Decho 
"com! -nargs=0 LWP	call ListWinPosn()                                    " Decho 

" ---------------------------------------------------------------------
" SaveUserMaps: this function sets up a script-variable (s:restoremap) {{{2
"          which can be used to restore user maps later with
"          call RestoreUserMaps()
"
"          mapmode - see :help maparg for details (n v o i c l "")
"                    ex. "n" = Normal
"                    The letters "b" and "u" are optional prefixes;
"                    The "u" means that the map will also be unmapped
"                    The "b" means that the map has a <buffer> qualifier
"                    ex. "un"  = Normal + unmapping
"                    ex. "bn"  = Normal + <buffer>
"                    ex. "bun" = Normal + <buffer> + unmapping
"                    ex. "ubn" = Normal + <buffer> + unmapping
"          maplead - see mapchx
"          mapchx  - "<something>" handled as a single map item.
"                    ex. "<left>"
"                  - "string" a string of single letters which are actually
"                    multiple two-letter maps (using the maplead:
"                    maplead . each_character_in_string)
"                    ex. maplead="\" and mapchx="abc" saves user mappings for
"                        \a, \b, and \c
"                    Of course, if maplead is "", then for mapchx="abc",
"                    mappings for a, b, and c are saved.
"                  - :something  handled as a single map item, w/o the ":"
"                    ex.  mapchx= ":abc" will save a mapping for "abc"
"          suffix  - a string unique to your plugin
"                    ex.  suffix= "DrawIt"
fun! SaveUserMaps(mapmode,maplead,mapchx,suffix)
"  call Dfunc("SaveUserMaps(mapmode<".a:mapmode."> maplead<".a:maplead."> mapchx<".a:mapchx."> suffix<".a:suffix.">)")

  if !exists("s:restoremap_{a:suffix}")
   " initialize restoremap_suffix to null string
   let s:restoremap_{a:suffix}= ""
  endif

  " set up dounmap: if 1, then save and unmap  (a:mapmode leads with a "u")
  "                 if 0, save only
  let mapmode  = a:mapmode
  let dounmap  = 0
  let dobuffer = ""
  while mapmode =~ '^[bu]'
   if     mapmode =~ '^u'
    let dounmap = 1
    let mapmode = strpart(a:mapmode,1)
   elseif mapmode =~ '^b'
    let dobuffer = "<buffer> "
    let mapmode  = strpart(a:mapmode,1)
   endif
  endwhile
"  call Decho("dounmap=".dounmap."  dobuffer<".dobuffer.">")
 
  " save single map :...something...
  if strpart(a:mapchx,0,1) == ':'
"   call Decho("save single map :...something...")
   let amap= strpart(a:mapchx,1)
   if amap == "|" || amap == "\<c-v>"
    let amap= "\<c-v>".amap
   endif
   let amap                    = a:maplead.amap
   let s:restoremap_{a:suffix} = s:restoremap_{a:suffix}."|:silent! ".mapmode."unmap ".dobuffer.amap
   if maparg(amap,mapmode) != ""
    let maprhs                  = substitute(maparg(amap,mapmode),'|','<bar>','ge')
	let s:restoremap_{a:suffix} = s:restoremap_{a:suffix}."|:".mapmode."map ".dobuffer.amap." ".maprhs
   endif
   if dounmap
	exe "silent! ".mapmode."unmap ".dobuffer.amap
   endif
 
  " save single map <something>
  elseif strpart(a:mapchx,0,1) == '<'
"   call Decho("save single map <something>")
   let amap       = a:mapchx
   if amap == "|" || amap == "\<c-v>"
    let amap= "\<c-v>".amap
"	call Decho("amap[[".amap."]]")
   endif
   let s:restoremap_{a:suffix} = s:restoremap_{a:suffix}."|silent! ".mapmode."unmap ".dobuffer.amap
   if maparg(a:mapchx,mapmode) != ""
    let maprhs                  = substitute(maparg(amap,mapmode),'|','<bar>','ge')
	let s:restoremap_{a:suffix} = s:restoremap_{a:suffix}."|".mapmode."map ".dobuffer.amap." ".maprhs
   endif
   if dounmap
	exe "silent! ".mapmode."unmap ".dobuffer.amap
   endif
 
  " save multiple maps
  else
"   call Decho("save multiple maps")
   let i= 1
   while i <= strlen(a:mapchx)
    let amap= a:maplead.strpart(a:mapchx,i-1,1)
	if amap == "|" || amap == "\<c-v>"
	 let amap= "\<c-v>".amap
	endif
	let s:restoremap_{a:suffix} = s:restoremap_{a:suffix}."|silent! ".mapmode."unmap ".dobuffer.amap
    if maparg(amap,mapmode) != ""
     let maprhs                  = substitute(maparg(amap,mapmode),'|','<bar>','ge')
	 let s:restoremap_{a:suffix} = s:restoremap_{a:suffix}."|".mapmode."map ".dobuffer.amap." ".maprhs
    endif
	if dounmap
	 exe "silent! ".mapmode."unmap ".dobuffer.amap
	endif
    let i= i + 1
   endwhile
  endif
"  call Dret("SaveUserMaps : restoremap_".a:suffix.": ".s:restoremap_{a:suffix})
endfun

" ---------------------------------------------------------------------
" RestoreUserMaps: {{{2
"   Used to restore user maps saved by SaveUserMaps()
fun! RestoreUserMaps(suffix)
"  call Dfunc("RestoreUserMaps(suffix<".a:suffix.">)")
  if exists("s:restoremap_{a:suffix}")
   let s:restoremap_{a:suffix}= substitute(s:restoremap_{a:suffix},'|\s*$','','e')
   if s:restoremap_{a:suffix} != ""
"   	call Decho("exe ".s:restoremap_{a:suffix})
    exe "silent! ".s:restoremap_{a:suffix}
   endif
   unlet s:restoremap_{a:suffix}
  endif
"  call Dret("RestoreUserMaps")
endfun

" ==============
"  Restore: {{{1
" ==============
let &cpo= s:keepcpo
unlet s:keepcpo

" ================
"  Modelines: {{{1
" ================
" vim: ts=4 fdm=marker
plugin/AutoAlign.vim	[[[1
193
" AutoAlign.vim: a ftplugin for C
" Author:	Charles E. Campbell, Jr.  <NdrOchip@ScampbellPfamily.AbizM>-NOSPAM
" Date:		Aug 09, 2012
" Version:	14j	ASTRO-ONLY
" GetLatestVimScripts: 884  1 :AutoInstall: AutoAlign.vim
" GetLatestVimScripts: 294  1 :AutoInstall: Align.vim
" GetLatestVimScripts: 1066 1 :AutoInstall: cecutil.vim
" ---------------------------------------------------------------------
"  Load Once: {{{1
if exists("b:didautoalign")
 finish
endif
let b:loaded_autoalign = "v14j"
let s:keepcpo          = &cpo
set cpo&vim

" ---------------------------------------------------------------------
" Debugging Support:
"if !exists("g:loaded_Decho") | runtime plugin/Decho.vim | endif
" DechoTabOn

" ---------------------------------------------------------------------
"  Support Plugin Loading: {{{1
" insure that cecutil's SaveWinPosn/RestoreWinPosn has been loaded
if !exists("*SaveWinPosn")
 silent! runtime plugin/cecutil.vim
endif

" ---------------------------------------------------------------------
" Public Interface: AA toggles AutoAlign {{{1
com! -nargs=0 AA				let b:autoalign= exists("b:autoalign")? !b:autoalign : 0|echo "AutoAlign is ".(b:autoalign? "on" : "off")
com! -count -nargs=0 AAstart	call s:AutoAlignStartline(<count>)

" ---------------------------------------------------------------------
"  AutoAlign: decides when to use Align/AlignMap {{{1
"    |i| : use b:autoalign_reqdpat{|i|} (ie. the i'th required pattern)
"          and b:autoalign_notpat{|i|}  (ie. the i'th not-pattern)
"    i<0 : trigger character has been encountered, but don't AutoAlign
"          if the reqdpat isn't present
fun! AutoAlign(i)
"  call Dfunc("AutoAlign(i=".a:i.") virtcol=".virtcol("."))
  call s:SaveUserSettings()

  " AutoAlign uses b:autoalign_reqdpat{|i|} and b:autoalign_notpat{|i|}
  " A negative a:i means that a trigger character has been encountered,
  " but not to AutoAlign if the reqdpat isn't present.
  let i= (a:i < 0)? -a:i : a:i
  if exists("b:autoalign") && b:autoalign == 0
   call s:RestoreUserSettings()
"   call Dret("AutoAlign : case b:autoalign==0")
   return ""
  endif
"  call Decho("i=".i)

  " sanity check: must have a reqdpat
  if !exists("b:autoalign_reqdpat{i}")
   call s:RestoreUserSettings()
"   call Dret("AutoAlign : b:autoalign_reqdpat{".i."} doesn't exist")
   return ""
  endif
"  call Decho("has reqdpat".i."<".b:autoalign_reqdpat{i}.">")
"  call Decho("match(<".getline(".").">,reqdpat".i."<".b:autoalign_reqdpat{i}.">)=".match(getline("."),b:autoalign_reqdpat{i}).")")

  " set up some options for AutoAlign
  let lzkeep= &lz
  let vekeep= &ve
  set lz ve=all

  if match(getline("."),b:autoalign_reqdpat{i}) >= 0
"   call Decho("current line matches b:autoalign_reqdpat{".i."}<".b:autoalign_reqdpat{i}.">")
   let curline   = line(".")
   if v:version >= 700
    let curposn   = SaveWinPosn(0)
    let nopatline = search(b:autoalign_notpat{i},'bW')
    call RestoreWinPosn(curposn)
   else
    let nopatline = search(b:autoalign_notpat{i},'bWn')
   endif

"   call Decho("nopatline=".nopatline." (using autoalign_notpat<".b:autoalign_notpat{i}.">)")
"   call Decho("b:autoalign (".(exists("b:autoalign")? "exists" : "doesn't exist").")")
"   call Decho("line('a)=".line("'a")." b:autoalign=".(exists("b:autoalign")? b:autoalign : -1)." curline=".curline." nopatline=".nopatline)

   if exists("b:autoalign") && line("'a") == b:autoalign && b:autoalign < curline && nopatline < line("'a")
"    call Decho("autoalign multi : b:autoalign_cmd{".i."}<".b:autoalign_cmd{i}.">")
	" break undo sequence and start new change
	"    exe "norm! i\<c-g>u\<esc>"     " cec 08/10/07 -- not sure if this is needed anymore
	let curline= line(".")
    exe b:autoalign_cmd{i}
	exe "keepj ".curline."norm! $"
   else
    let b:autoalign= line(".")
    ka
"	call Decho("autoalign start")
   endif

  elseif exists("b:autoalign")
   " trigger character encountered, but reqdpat not present
"   call Decho("trigger char present, but doesn't match b:autoalign_reqdpat{".i."}<".b:autoalign_reqdpat{i}.">")
   if a:i > 0
    unlet b:autoalign
"    call Decho("autoalign suspend")
   endif

  elseif exists("b:autoalign_suspend{i}")
   " trigger character encounted, but reqdpat not present, but takes more than
   " one trigger
"   call Decho("trigger char present, doesn't match b:autoalign_reqdpat{".i."}<".b:autoalign_reqdpat{i}.">, takes more than one trigger")
   if match(getline("."),b:autoalign_suspend{i}) >= 0
	if exists("b:autoalign")
     unlet b:autoalign
	endif
"    call Decho("autoalign suspend: matches autoalign_suspend<".b:autoalign_suspend{i}.">")
   endif
"  else " Decho
"   call Decho("b:autoalign_reqdpat{".i."} doesn't match, b:autoalign doesn't exist, b:autoalign_suspend{".i."} doesn't exist")
  endif

  " Handle AutoAlign funcrefs (if any)
  if exists("g:AutoAlign_funcref".i)
"   call Decho("(AutoAlign) handle optional Funcrefs; g;AutoAlign_funcref".i." exists")
   if type(g:AutoAlign_funcref{i}) == 2
"    call Decho("(AutoAlign) handling a g:AutoAlign_funcref")
	keepj call g:AutoAlign_funcref{i}()
   elseif type(g:AutoAlign_funcref{i}) == 3
"	call Decho("(AutoAlign) handling a list of g:AutoAlign_funcref".i."s")
	for Fncref in g:AutoAlign_funcref{i}
     if type(FncRef) == 2
      keepj call FncRef()
     endif
    endfor
   endif
  endif

"  call Decho("virtcol=".virtcol("."))
  let lasttrig= b:autoalign_trigger{i}[strlen(b:autoalign_trigger{i})-1]
  if col("$") == col(".")
   startinsert!
  else
"  call Decho("(resume) exe norm! lF".lasttrig."l")
   exe "norm! lF".lasttrig."l"
   startinsert
  endif
  call s:RestoreUserSettings()

"  call Dret("AutoAlign : @.<".@..">")
  return ""
endfun

" ---------------------------------------------------------------------
" s:AutoAlignStartline: {{{2
fun! s:AutoAlignStartline(sl)
"  call Dfunc("s:AutoAlignStartline(sl=".a:sl.")")
  if a:sl == 0
   let b:autoalign= line(".")
   ka
  elseif a:sl > line("$")
   let b:autoalign= line("$")
   exe line("$")."ka"
  else
   let b:autoalign= a:sl
   exe a:sl."ka"
  endif
"  call Dret("s:AutoAlignStartline")
endfun

" ---------------------------------------------------------------------
" SaveUserSettings: {{{1
fun! s:SaveUserSettings()
"  call Dfunc("SaveUserSettings()")
  let b:keep_lz   = &l:lz
  let b:keep_magic= &magic
  let b:keep_remap= &l:remap
  let b:keep_ve   = &l:ve
  setlocal magic lz ve=all remap
"  call Dret("SaveUserSettings")
endfun

" ---------------------------------------------------------------------
" RestoreUserSettings: {{{1
fun! s:RestoreUserSettings()
"  call Dfunc("RestoreUserSettings()")
  let &l:lz    = b:keep_lz
  let &magic   = b:keep_magic
  let &l:remap = b:keep_remap
  let &l:ve    = b:keep_ve
"  call Dret("RestoreUserSettings")
endfun

let &cpo= s:keepcpo
unlet s:keepcpo
" ---------------------------------------------------------------------
" vim: ts=4 fdm=marker
ftplugin/bib/AutoAlign.vim	[[[1
18
" AutoAlign: ftplugin support for bib
" Author:    Charles E. Campbell, Jr.
" Date:      Aug 16, 2007
" Version:   13
" ---------------------------------------------------------------------
let b:loaded_autoalign_bib= "v13"
"call Decho("loaded ftplugin/bib/AutoAlign!")

"  overloading '=' to keep things lined up {{{1
ino <silent> = =<c-r>=AutoAlign(1)<cr>
let b:autoalign_reqdpat1= '^\(\s*\h\w*\(\[\d\+]\)\{0,}\(->\|\.\)\=\)\+\s*[-+*/^|%]\=='
let b:autoalign_notpat1 = '^[^=]\+$'
let b:autoalign_trigger1= '='
if !exists("g:mapleader")
 let b:autoalign_cmd1    = 'norm \t=$'
else
 let b:autoalign_cmd1    = "norm ".g:mapleader."t=$"
endif
ftplugin/c/AutoAlign.vim	[[[1
19
" AutoAlign: ftplugin support for C
" Author:    Charles E. Campbell, Jr.
" Date:      Jan 06, 2011
" Version:   16d	ASTRO-ONLY
" ---------------------------------------------------------------------
if &ft != "cpp"
 let b:loaded_autoalign_c = "v16d"

 "  overloading '=' to keep things lined up {{{1
 ino <silent> = =<c-r>=AutoAlign(1)<cr>
 let b:autoalign_reqdpat1 = '^\([ \t*]\{0,}\h\w*\%(\[\%(\d\+\|\h\w*\)\=\]\)\{0,}\%(->\|\.\)\=\)\+\s*[-+*/^|%]\=='
 let b:autoalign_notpat1  = '^[^=]\+$\|\<\%(for\|if\|while\)\s*(\|\<else\>'
 let b:autoalign_trigger1 = '='
 if !exists("g:mapleader")
  let b:autoalign_cmd1     = 'norm \t=$'
 else
  let b:autoalign_cmd1     = "norm ".g:mapleader."t=$"
 endif
endif
ftplugin/cpp/AutoAlign.vim	[[[1
53
" AutoAlign: ftplugin support for C++
" Author:    Charles E. Campbell, Jr.
" Date:      Jan 06, 2011
" Version:   15a	ASTRO-ONLY
" ---------------------------------------------------------------------
let b:loaded_autoalign_cpp= "v15a"

"  overloading '=' to keep things lined up {{{1
ino <silent> = =<c-r>=AutoAlign(1)<cr>
let b:autoalign_reqdpat1 = '^\([ \t*]\{0,}\h\w*\%(\[\%(\d\+\|\h\w*\)]\)\{0,}\%(->\|\.\)\=\)\+\s*[-+*/^|%]\=='
let b:autoalign_notpat1  = '^[^=]\+$'
let b:autoalign_trigger1 = '='
if !exists("g:mapleader")
 let b:autoalign_cmd1     = 'norm \t=$'
else
 let b:autoalign_cmd1     = "norm ".g:mapleader."t=$"
endif

"  overloading '<<' to keep things lined up {{{1
"ino <silent> < <<c-o>:silent call AutoAlign(-2)<cr>
ino <silent> < <<c-r>=AutoAlign(-2)<cr>
let b:autoalign_reqdpat2 = '<<'
let b:autoalign_notpat2  = '^\%(\%(<<\)\@!.\)*$'
let b:autoalign_trigger2 = '<'
if !exists("g:mapleader")
 let b:autoalign_cmd2     = 'norm \a<$'
else
 let b:autoalign_cmd2     = "norm ".g:mapleader."a<$"
endif

"  overloading '>>' to keep things lined up {{{1
"ino <silent> > ><c-o>:silent call AutoAlign(-3)<cr>
ino <silent> > ><c-r>=AutoAlign(-3)<cr>
let b:autoalign_reqdpat3 = '>>'
let b:autoalign_notpat3  = '^\%(\%(>>\)\@!.\)*$'
let b:autoalign_trigger3 = '>'
if !exists("g:mapleader")
 let b:autoalign_cmd3     = 'norm \a<$'
else
 let b:autoalign_cmd3     = "norm ".g:mapleader."a<$"
endif

"  overloading '//' to keep things lined up {{{1
"ino <silent> / /<c-o>:silent call AutoAlign(-4)<cr>
ino <silent> / /<c-r>=AutoAlign(-4)<cr>
let b:autoalign_reqdpat4 = '//'
let b:autoalign_notpat4  = '^\%(\%(//\)\@!.\)*$'
let b:autoalign_trigger4 = '/'
if !exists("g:mapleader")
 let b:autoalign_cmd4     = 'norm \acom'
else
 let b:autoalign_cmd4     = "norm ".g:mapleader."acom"
endif
ftplugin/eltab/AutoAlign.vim	[[[1
17
" AutoAlign: ftplugin support for elastic tabs
" Author:    Charles E. Campbell, Jr.
" Date:      Aug 29, 2007
" Version:   1
" ---------------------------------------------------------------------
let b:loaded_autoalign_eltab = "v1"

" overloading '<tab>' to keep things lined up {{{1
ino <silent> <tab> <tab><c-r>=AutoAlign(1)<cr>
let b:autoalign_reqdpat1 = "\t"
let b:autoalign_notpat1  = '^\%(\%(\t\)\@!.\)*$'
let b:autoalign_trigger1 = "\t"
if !exists("g:mapleader")
 let b:autoalign_cmd1     = 'norm \tab'
else
 let b:autoalign_cmd1     = "norm ".g:mapleader.'tab'
endif
ftplugin/html/AutoAlign.vim	[[[1
18
" AutoAlign: ftplugin support for HTML
" Author:    Charles E. Campbell, Jr.
" Date:      Aug 16, 2007
" Version:   13
" ---------------------------------------------------------------------
let b:loaded_autoalign_html= "v13"

"  overloading '>' to keep things lined up {{{1
ino <silent> > ><c-r>=AutoAlign(-1)<cr>
let b:autoalign_reqdpat1 = '</[tT][rR]>$'
let b:autoalign_notpat1  = '\%(</[tT][rR]>\)\@!.\{5}$'
let b:autoalign_suspend1 = '\c</\=table>'
let b:autoalign_trigger1 = '>'
if !exists("g:mapleader")
 let b:autoalign_cmd1     = 'norm \Htd$'
else
 let b:autoalign_cmd1     = "norm ".g:mapleader."\Htd$"
endif
ftplugin/maple/AutoAlign.vim	[[[1
13
" AutoAlign: ftplugin support for Maple
" Author:    Charles E. Campbell, Jr.
" Date:      Aug 16, 2007
" Version:   14
" ---------------------------------------------------------------------
let b:loaded_autoalign_maple = "v14"

"  overloading '=' to keep things lined up {{{1
ino <silent> := :=<c-r>=AutoAlign(1)<cr>
let b:autoalign_reqdpat1 = ':='
let b:autoalign_notpat1  = '^\%(\%(:=\)\@!.\)*$'
let b:autoalign_trigger1 = ':='
let b:autoalign_cmd1     = "'a,.Align :="
ftplugin/matlab/AutoAlign.vim	[[[1
17
" AutoAlign: ftplugin support for MatLab
" Author:    Charles E. Campbell, Jr.
" Date:      Aug 16, 2007
" Version:   13
" ---------------------------------------------------------------------
let b:loaded_autoalign_matlab = "v13"

"  overloading '=' to keep things lined up {{{1
ino <silent> = =<c-r>=AutoAlign(1)<cr>
let b:autoalign_reqdpat1 = '\%(^.*=\)\&\%(^\s*\%(\%(if\>\|elseif\>\|function\>\|while\>\|for\>\)\@!.\)*$\)'
let b:autoalign_notpat1  = '^[^=]\+$'
let b:autoalign_trigger1 = '='
if !exists("g:mapleader")
 let b:autoalign_cmd1     = 'norm \t=$'
else
 let b:autoalign_cmd1     = "norm ".g:mapleader."t=$"
endif
ftplugin/tex/AutoAlign.vim	[[[1
18
" AutoAlign: ftplugin support for LaTeX
" Author:    Charles E. Campbell, Jr.
" Date:      Aug 16, 2007
" Version:   13
" ---------------------------------------------------------------------
let b:loaded_autoalign_tex = "v13"

"  overloading '\' to keep things lined up {{{1
"ino <silent> \\ \\<c-o>:silent call AutoAlign(1)<cr>
ino <silent> \\ \\<c-r>=AutoAlign(1)<cr>
let b:autoalign_reqdpat1 = '^\([^&]*&\)\+[^&]*\\\{2}'
let b:autoalign_notpat1  = '^.*\(\\\\\)\@<!$\&^.'
let b:autoalign_trigger1 = '\\'
if !exists("g:mapleader")
 let b:autoalign_cmd1     = 'norm \tt$'
else
 let b:autoalign_cmd1     = "norm ".g:mapleader."tt$"
endif
ftplugin/vim/AutoAlign.vim	[[[1
18
" AutoAlign: ftplugin support for vim
" Author:    Charles E. Campbell, Jr.
" Date:      Aug 16, 2007
" Version:   13
" ---------------------------------------------------------------------
let b:loaded_autoalign_vim = "v13"

"  overloading '=' to keep things lined up {{{1
"ino <silent> = =<c-o>:silent call AutoAlign(1)<cr>
ino <silent> = =<c-r>=AutoAlign(1)<cr>
let b:autoalign_reqdpat1 = '^\s*let\>.*='
let b:autoalign_notpat1  = '^[^=]\+$'
let b:autoalign_trigger1 = '='
if !exists("g:mapleader")
 let b:autoalign_cmd1     = 'norm \t=$'
else
 let b:autoalign_cmd1     = "norm ".g:mapleader."t=$"
endif
doc/AutoAlign.txt	[[[1
343
*AutoAlign.txt*		Automatic Alignment		May 21, 2012

Author:  Charles E. Campbell, Jr.  <NdrOchip@ScampbellPfamily.AbizM>
(remove NOSPAM from Campbell's email first)
Copyright: (c) 2004-2011 by Charles E. Campbell, Jr.	*autoalign-copyright*
           The VIM LICENSE applies to AutoAlign.vim and AutoAlign.txt
           (see |copyright|) except use "AutoAlign" instead of "Vim"
	   No warranty, express or implied.  Use At-Your-Own-Risk.

==============================================================================
1. Contents				*autoalign* *autoalign-contents*

    1. Contents.................: |autoalign-contents|
    2. Installing...............: |autoalign-install|
    3. AutoAlign Tutorial.......: |autoalign-tutorial|
    4. AutoAlign Manual.........: |autoalign-manual|
    5. AutoAlign Internals......: |autoalign-internals|
    6. Elastic Tabs.............: |autoalign-elastictabs|
    7. AutoAlign History........: |autoalign-history|

==============================================================================
2. Installing AutoAlign					*autoalign-install*

        1. AutoAlign needs the Align/AlignMaps utilities
           which are available from either:
>
                http://vim.sourceforge.net/scripts/script.php?script_id=294
                http://mysite.verizon.net/astronaut/vim/index.html#AUTOALIGN
<
        2. Using vim 7.1 or later: >

              vim AutoAlign.vba.gz
               :so %
               :q
<
           This process will generate the following files on your runtimepath: >

                plugin/cecutil.vim
                ftplugin/bib/AutoAlign.vim
                ftplugin/c/AutoAlign.vim
                ftplugin/cpp/AutoAlign.vim
                ftplugin/maple/AutoAlign.vim
                ftplugin/tex/AutoAlign.vim
                ftplugin/vim/AutoAlign.vim
<

        3. To enable plugins and filetype plugins generally, including
           AutoAlign, have the following in your <.vimrc> file:
>
                "  Initialize: {{{1
                set nocp
                if version >= 600
                 filetype plugin indent on
                endif
<

==============================================================================
3. AutoAlign Tutorial 					  *autoalign-tutorial*

        The tutorial assumes that you have already installed AutoAlign and the
        Align/AlignMap plugins.

        Example 1: when using C >
                        x= 1;
                        yy= 2;
                        zzz= 3;
<               Results in >
                        x= 1;
<               and then >
                        x  = 1;
                        yy = 2;
<               and finally >
                        x   = 1;
                        yy  = 2;
                        zzz = 3;
<               with the auto-alignment occurring upon the entry of the "="s.
                Such alignments will not occur when the line begins with for,
                if, while, or else.

        Example 2: using C++ >
                        x= 1;
                        yy= 2;
                        zzz= 3;
<               with alignment occuring like it does with C. >
                        x   = 1;
                        yy  = 2;
                        zzz = 3;
<               C++ auto-alignment also handles << and >> operators, and for
                C++ style comments (ie. //... ).

        Example 3: using LaTeX >
                  \begin{center}\begin{tabular}{||l|l|l||}
                        \hline\hline
                        a&b&c\\
<               Nothing seems to happen so far. With the next line: >
                        dd&ee&ff\\
<               The trailing double-backslash triggers the alignment package,
                yielding >
                        a  & b  & c  \\
                        dd & ee & ff \\
<
        Example 4: using Maple >
                        eq1:= x= 3*y + z;
                        eq1a:= x= 3*y + 2*z;
<               Upon entry of the second line's ":=", the AutoAlign package will align
                the ":="s, yielding >
                        eq1  := 3*y + z;
                        eq1a :=
<

==============================================================================
4. AutoAlign Manual				*autoalign-man* *autoalign-manual*

    The AutoAlign filetype plugins operate while vim is in insert mode.  They
    apply appropriate Align/AlignMaps to the most recent contiguous region,
    thereby keeping such things as "=" aligned.  See |align| and |alignmaps|.

					*autoalign-AA* *autoalign-AAstart*
    There are two commands supported by AutoAlign: >

        :AA             - toggles AutoAlign on and off
        :AAstart        - manually set the current insertion block to start at
                          the current line
        :[line]AAstart  - manually set the current insertion block to start at
                          the specified line
        :AAstart [line] - manually set the current insertion block to start at
                          the specified line
<
    The mark 'a is used by AutoAlign to indicate where the start of the
    automatic alignment region begins.  Changing 'a to some other place will
    also stop AutoAlign from operating on that region.  One may temporarily
    suppress AutoAlignment that way.

              Language  AutoAlignment   AutoAlignment
                            Trigger        Taken On
              --------  -------------   -------------
                bib           =               =
                c             =               =
                cpp           =               =
                              <              <<
                              >              >>
                maple         =              :=
                tex           \            & and \\
                vim           =               =

    The AutoAlignment trigger character invokes a call to the appropriate
    filetype's AutoAlign.  Only when:

    * the current line matches a filetype specific pattern (to avoid
    aligning <= >= == etc)

    * the b:autoalign_vim variable records the first line which
    satisfied the filetype specific pattern in the current
    region.  If it matches the mark ('a)'s line, then AutoAlignment
    will occur.  Thus the user can temporarily disable AutoAlignment
    on the current region merely by changing where the mark 'a is
    set to.

    * Although frequently the trigger character is also used in
    the alignment, sometimes a longer pattern is used (ex. maple's
    :=) for alignment.

    The AutoAlign plugin is fairly trivial to use -- just type.  Alignment
    will occur for the following patterns automatically.  These patterns
    are stored in b:autoalign_reqdpat1, b:autoalign_reqdpat2, etc.

    FILETYPE PATTERNS

    bib    ^\(\s*\h\w*\(\[\d\+]\)\{0,}\(->\|\.\)\=\)\+\s*[-+*/^|%]\==
    c      ^\(\s*\*\{0,}\h\w*\%(\[\%(\d\+\|\h\w*\)]\)\{0,}\%(->\|\.\)\=\)\+\s*[-+*/^|%]\==
    cpp    ^\(\s*\h\w*\(\[\d\+]\)\{0,}\(->\|\.\)\=\)\+\s*[-+*/^|%]\==
    cpp    <<
    cpp    >>
    maple  :=
    matlab \%(^.*=\)\&\%(^\s*\%(\%(if\>\|elseif\>\|while\>\|for\>\)\@!.\)*$
    tex    ^\([^&]*&\)\+[^&]*\\\{2
    vim    ^\s*let\>.*=

    AutoAlign looks backwards from the current line, searching for the first
    preceding line _not_ containing the pattern.  It uses b:autoalign_notpat1,
    b:autoalign_notpat2, etc for this.  If the "not pattern" has moved since
    the mark ('a) was made, AutoAlign will start aligning from the current
    line.

    AUTOALIGN FUNCREF				*AutoAlign_funcref*

    When AutoAlign is invoked and changes the line, an optional function
    (or functions) may be called via |Funcref|(s): >

    	let g:AutoAlign_funcref10= function("SomeFunctionName")
<   or a list of such |Funcref|(s): >
    	let g:AutoAlign_funcref10=[function("SomeFunctionName"),function("AnotherFunc"]
<   These functions will be executed after the aligning has been done, but
    before control has been passed back to the user via a |:startinsert|.

==============================================================================
5. AutoAlign Internals					*autoalign-internals*

    AutoAlign is triggered to operate during insert mode when a special
    character (such as "=") is encountered using an inoremap.  Each ftplugin
    specifies its own triggers.  The inoremap turns virtualedit off, calls
    AutoAlign(), and then deletes the trigger character (which may have or may
    not have moved) and then inserts it to keep the operation otherwise
    transparent.

    AutoAlign attempts to perform its automatic alignment on an "AutoAlign
    region".  Alignment, of course, is performed over that region.  The idea
    is to start an AutoAlign region upon receipt of a trigger character and
    a matching required pattern; subsequently, alignment is done over the
    AutoAlign region is active and whenever the region has more than one line
    in it.

    Such a region begins with the presence of a required pattern.  That first
    line is also marked with mark-a ('a).  If the mark 'a is moved, then the
    AutoAlign region is terminated.  There are several ways that an AutoAlign
    region may be terminated; see below.

    Associated with each trigger character are three or four patterns.  Also,
    each trigger character inoremap is to have an associated count, referred
    to as "#" below.
>
    b:autoalign_reqdpat#
<       This pattern is required for AutoAlign to deem that an AutoAlign
        region has started.  If a positive # is passed to AutoAlign(), then
        the required pattern is needed to allow the AutoAlign region to
        continue whenever a trigger character is encountered.  A negative #, a
        trigger character, and a failed match to b:autoalign_reqdpat# will
        terminate the AutoAlign region.
>
    b:autoalign_notpat#
<       This pattern must match just before the AutoAlign region starts.  It
        is used to search before the current line.  If the non-pattern
        matching line is not the same as it was when the AutoAlign region
        began, then the AutoAlign region is terminated.
>
    b:autoalign_suspend#
<       This pattern is optional; if it matches, the AutoAlign region is
    terminated.  The fplugin/html/AutoAlign.vim script uses </table>, for
        example, to terminate table aligning.
>
    b:autoalign_cmd#
<       This is the command used to invoke alignment on the AutoAlign region.
>
    b:autoalign_trigger#
<       This variable holds the trigger character.

    Of course, the :AA command is also available to turn AutoAlign off.


==============================================================================
6. Elastic Tabs			*autoalign-eltab* *autoalign-elastictabs*

Those of you who are interested in "elastic" non-uniform tab stops may find
the "eltab" filetype of use.  Its not a pure non-uniform tab solution (that
would take a modification to vim itself); however, a filetype of eltab coupled
with AutoAlign makes for an almost elastic-tab solution.

If the tabstop is set to 1 (:set ts=1), then AlignMaps' \tab will do a
no-padding alignment on the tabs.  Thus one gets tabs surrounded by spaces to
do the alignment (with no additional padding).

If your file has a modeline: >

        vim: ft=eltab
<
Subsequently, as you type, tabs will be auto-aligned within each current insertion
block of text; total file alignment can be done with 1V$\tab (ie. select
entire file, align it).


==============================================================================
7. AutoAlign History					*autoalign-history*

   14 : Sep 20, 2007 * now using startinsert! instead of startinsert.
   		       Currently not using the various autoalign_trigger
		       strings; will see how modification works out.
		     * found some cases where startinsert! isn't a good
		       idea (ex. inserting an "=").  New modification;
		       this one may use the autoalign_trigger string.
		     * The c plugin's AutoAlign.vim was overriding
		       the c++ plugin's AutoAlign.vim settings.
	Feb 22, 2011 * for menus, &go =~# used to insure correct case
	Apr 25, 2012 * added |AutoAlign_funcref|
   13 : Oct 19, 2006 * ftplugin/cpp/AutoAlign.vim fixed for < and >.
                       Introduced b:autoalign_trigger# so AutoAlign
		       can put cursor back where it belongs.
		     * AutoAlign now pluginkiller immune
	Mar 26, 2007 * AutoAlign's invocation of Align sometimes caused
		       the cursor to jump to the first line rather than
		       the current line (ex: for Maple's :=).  Fixed.
	Aug 15, 2007 * Changed the imaps's right-hand-side to use,
		       typically, =<c-r>=AutoAlign(#) instead of
		       =<c-o>:silent call AutoAlign(#).
		       Thanks to Antony Scriven!  Gets that "|.|"
		       repeater working.
   12 : Sep 19, 2006 * ftplugin/bib/AutoAlign.vim fixed
   11 : Mar 23, 2006 * v10 had debugging enabled; this one has debugging
		       deactivated.
		     * now decides to use startinsert vs startinsert!
		       before the alignment by using the "atend" variable,
		       which holds the result of testing whether the cursor
		       is at the end-of-line or not.
   10 : Mar 16, 2006 * using startinsert! to recommence editing
		       AutoAlign only triggered when the trigger character
		       is at the end of the current line being inserted.
		     * works with ve=all and ve=  (see |'ve'|)
    9 : Mar 16, 2006 * seems to have stopped working with virtualedit off.
		       Now works with virtualedit off or on.  If vim 7.0
		       is in use, AutoAlign doesn't use SaveWinPosn()
		       or RestoreWinPosn(), so it may work faster.
    8 : Jan 18, 2006 * cecutil updated to use keepjumps
		     * plugin/AutoAlign.vim was missing from distribution
    7 : Mar 31, 2005 * supports html
		     * b:autoalign_suspend# for suspend-alignment pattern
		       implemented, along with using AutoAlign(-#) to avoid
		       having a reqdpat failure doing an AutoAlign suspension.
		       The absolute value of # is used to refer to
		       b:autoalign_reqdpat#, b:autoalign_notpat#, and
		       b:autoalign_suspend#.
        Apr 22, 2005 * sanity check included to prevent an attempt to access
		       an undefined variable (b:autoalign_reqdpat{i})
    6 : Mar 30, 2005 * AutoAlign is split into a plugin containing the
		       majority of vimscript; the supported ftplugins
		       contain the invoking imaps and pattern definitions
		       that the plugin uses.
    5 : Jan 24, 2005 * first release of AutoAlign using vim's user-help.
		     * using g:mapleader instead of a built-in backslash to
		       access AlignMaps
		     * map and function changed to allow use of "." to
		       repeat entry of =... expressions.
    4, Jul 02, 2004  * see |i_CTRL-G_u| -- breaks undo sequence at every align
    3, Mar 03, 2004  * autoalign not taken if a no-pattern line is
		       in-between the keepalign line and the current line
    2                * b:autoalign==0: turns autoalign off
		       b:autoalign==1: turns autoalign back on
		     * 'a now used during autoalign, and AlignMap's \t=
		       If user changes 'a, then AutoAlign recognizes that
		       it is not to keep aligning
		     * The :AA command can be used to toggle AutoAlign
    1                * The Epoch

==============================================================================
vim:tw=78:ts=8:ft=help
ftplugin/eltab/eltab.vim	[[[1
18
" eltab.vim
"   Author: Charles E. Campbell, Jr.
"   Date:   Jun 22, 2010
"   Version: 1a	NOT RELEASED
" ---------------------------------------------------------------------
"  Load Once: {{{1
if &cp || exists("g:loaded_ftplugin_eltab")
 finish
endif
let g:loaded_ftplugin_eltab = "v1a"
let s:keepcpo               = &cpo
set cpo&vim

" ---------------------------------------------------------------------
"  Restore: {{{1
let &cpo= s:keepcpo
unlet s:keepcpo
" vim: ts=4 fdm=marker
