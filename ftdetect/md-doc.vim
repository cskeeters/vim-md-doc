" Need to call MdDocInit when we enter a buffer in a markdown directory
augroup md-doc
    autocmd!

    for pair in g:md_doc
        let path = pair[0]
        let host = pair[1]
        execute "autocmd BufRead,BufNewFile ".path."/* call MdDocInit('".host."')"
    endfor
augroup END

function! MdDocInit(host)
    if &buftype != ''
        return
    endif

    if !exists("g:md_doc_auto_commit") || g:md_doc_auto_commit != 1
        echo "MdDocInit (Auto-Commit Disabled)"
    else
        echo "MdDocInit (Auto-Commit Enabled)"
    endif

    " In case we don't use a markdown extension on our file names
    set filetype=markdown

    nmap <buffer> <localleader>s :call MdDocAutoCommitToggle()<cr>
    nmap <buffer> <localleader>c :call MdDocCommit("%")<cr>

    "View in browser
    execute "nnoremap <buffer> <localleader>v :update<cr>:!open http://".a:host."/%:t<cr>"

    " Call MdDocCommit when buffer is closed to commit
    augroup md-docsave
        autocmd!
        autocmd VimLeavePre,BufDelete <buffer> call MdDocBufferClosed()
    augroup END
endfunction

function! MdDocAutoCommitToggle()
    if !exists("g:md_doc_auto_commit") || g:md_doc_auto_commit != 1
        let g:md_doc_auto_commit = 1
        echo "Enabled Auto-Commit"
    else
        let g:md_doc_auto_commit = 0
        echo "Disabled Auto-Commit"
    endif
endfunction

function! MdDocBufferClosed()
    " Only commit if g:md_doc_auto_commit is equal to 1
    if !exists("g:md_doc_auto_commit") || g:md_doc_auto_commit != 1
        return
    else
        call MdDocCommit("<afile>")
    endif
endfunction

function! MdDocCommit(filespec)
    let repo_root=expand(a:filespec.":h")
    let filename=expand(a:filespec.":t")
    let filepath=expand(a:filespec."")

    " Make sure the file was saved if new
    if empty(glob(l:filepath))
        return
    endif

    " Need to ignore __CLOSER__ and __TagBar__
    if match(l:filename, '_.*') != -1
        return
    endif

    "echom "Looking for VCS"

    " Is Mercurial repository
    if !empty(glob(repo_root."/.hg"))
        "echom "Detected Mercurial Repository."
        let l:action="Modified"
        let l:unknowns=systemlist("hg sta -R ".repo_root." -un ".filepath)
        if len(l:unknowns) > 0
            echom "Adding file ".filename
            let l:action="Added"
            silent execute "!hg add -R ".repo_root." ".filepath
        endif
        let l:modified=systemlist("hg sta -R ".repo_root." -amn ".filepath)
        if len(l:modified) > 0
            let l:msg="Auto-Commit: ".l:action." ".filename
            let l:msg=inputdialog("Commit Message (ESC to cancel):", l:msg)
            if l:msg != ""
                echom "Committing file ".filename
                silent execute "!hg commit -R ".repo_root." ".filepath." -m '".l:msg."'"
            endif
        endif
    endif
endfunction
