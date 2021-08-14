syntax clear
syntax case ignore

let s:comment_color = "guifg=#3c425f ctermfg=14"
let s:checked_color = "guifg=#565f89 ctermfg=14"

" comments
" ========
syntax match todayComment /^--.*/ contains=todayHeader,todayBrokenHeader,todayHeaderDivider
syntax match todayHeader /^-- \zs.*\ze {{{/ contained contains=todayHeaderDivider
syntax match todayHeaderDivider /|/ contained
syntax match todayBrokenHeader /^-- \zsbroken\ze (/ contained

syntax match todayFirstHeaderElement /^-- \zs[^|]\+\ze.* \(|\|{\)/ contained
syntax match todayMiddleHeaderElement /|.*|/ contained
syntax cluster todayHeaderElement add=todayFirstHeaderElement,todayMiddleHeaderElement

exec "highlight default todayComment " . s:comment_color
exec "highlight default todayCategory gui=bold,underline " . s:comment_color
exec "highlight default todayCategoryDate gui=italic " . s:comment_color
highlight default link todayFirstHeaderElement todayHeaderElement


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
" ====

let s:do_date_pattern =
    \ '\%('
    \ .. join(luaeval("require('today.syntax').do_date_patterns"), '\|')
    \ .. '\)'

let s:recur_pattern =
    \ '\s*\%(+\%('
    \ .. join(luaeval("require('today.syntax').recur_patterns"), '\|')
    \ .. '\)\)\?'

exec 'syntax match todayDateSpec '
    \ .. '/\zs<\s*'
    \ .. s:do_date_pattern
    \ .. s:recur_pattern
    \ .. '>\ze/'
    \ .. ' contains=todayRecur,todayDoDatePast'

exec 'syntax match todayRecur /' .. s:recur_pattern .. '/ contained'
syntax match todayDoDatePast /\(yesterday\|\d\+ days ago\)/ contained

highlight default link todayDateSpec Identifier
highlight default link todayRecur Identifier
highlight default link todayDoDatePast ErrorMsg

" priorities
" ==========
syntax match todayPriorityHigh /\v(^|\s)\zs!!\ze($|\s)/
syntax match todayPriorityLow /\v(^|\s)\zs!\ze($|\s)/

highlight default todayPriorityHigh gui=bold guifg=#ff4444
highlight default todayPriorityLow gui=bold guifg=#ffa500

" tags
" ====
syntax match todayTag /\v#\w+/
highlight default todayTag gui=bold,underline
