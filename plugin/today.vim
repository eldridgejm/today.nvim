func TodayReload()
lua << EOF
    -- reload plugin packages
    for k in pairs(package.loaded) do
        if k:match("^today") then
            package.loaded[k] = nil
        end
    end
EOF
endfunction
