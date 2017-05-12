if exists("loaded_md_doc")
    finish
endif
let loaded_md_doc = 1

function! s:MdDocOpen(url)
    let browsers=["xdg-open", "gnome-open", "open", "firefox", "chrome"]
    for browser in browsers
        if executable(browser)
            echom browser
            exec "!".l:browser." ".shellescape(a:url,0)
            break
        endif
    endfor
endfunction

command! -nargs=1 MdDocOpen :call s:MdDocOpen(<q-args>)
