syntax clear
syntax case ignore

let s:comment_color = "guifg=#565f89 ctermfg=14"
let s:checked_color = "guifg=#565f89 ctermfg=14"

" comments
" ========
syntax match todayComment /^--.*/ contains=todaySection
syntax match todaySection /^--\s\zs.*\ze\s{{{/ contained
exec "highlight default todayComment " . s:comment_color
exec "highlight default todaySection gui=bold,underline " . s:comment_color

" checkboxes
" ==========
syntax match todayCheckboxUnchecked /^\[.\]/
highlight default todayCheckboxUnchecked gui=bold

" the entire line of a checked-off task
syntax match todayCheckboxCheckedLine /^\[x\].*/ contains=todayCheckboxChecked
exec "highlight default todayCheckboxCheckedLine gui=strikethrough " . s:checked_color

" the checkbox itself
syntax match todayCheckboxChecked /^\[x\]/ contained
exec "highlight default todayCheckboxChecked gui=strikethrough,bold " . s:checked_color

" dates
" =====
syntax match todayDate /<.*>/
highlight default link todayDate Identifier

" priorities
" ==========
syntax match todayPriorityHigh /\v(^|\s)\zs!!\ze($|\s)/
syntax match todayPriorityLow /\v(^|\s)\zs!\ze($|\s)/

highlight default todayPriorityHigh gui=bold guifg=#ff4444
highlight default todayPriorityLow gui=bold guifg=#ffa500
