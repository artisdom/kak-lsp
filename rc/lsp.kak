decl str lsp_cmd 'nc localhost 31337 -c'
decl -hidden completions lsp_completions
decl -hidden range-specs lsp_errors

decl -hidden range-specs cquery_semhl

def lsp-did-change %{
    decl -hidden str lsp_draft %sh{ mktemp }
    eval -no-hooks write %opt{lsp_draft}
    nop %sh{ (printf '
session = "%s"
client  = "%s"
buffile = "%s"
version = %d
method  = "textDocument/didChange"
[params]
draft   = "%s"
' "${kak_session}" "${kak_client}" "${kak_buffile}" "${kak_timestamp}" "${kak_opt_lsp_draft}" | ${kak_opt_lsp_cmd}) > /dev/null 2>&1 < /dev/null & }
}

def lsp-completion %{
    decl -hidden str lsp_completion_offset
    eval -draft %{ try %{
        execute-keys <esc><a-h>s\w+.\z<ret>
        set window lsp_completion_offset %sh{echo $(expr ${#kak_selection} - 1)}
    } catch %{
        set window lsp_completion_offset "0"
    }}
    nop %sh{ (printf '
session   = "%s"
client    = "%s"
buffile   = "%s"
version   = %d
method    = "textDocument/completion"
[params.position]
line      = %d
character = %d
[params.completion]
offset    = %d
' "${kak_session}" "${kak_client}" "${kak_buffile}" "${kak_timestamp}" $(expr ${kak_cursor_line} - 1) $(expr ${kak_cursor_column} - 1) ${kak_opt_lsp_completion_offset} | ${kak_opt_lsp_cmd}) > /dev/null 2>&1 < /dev/null & }
}

def lsp-hover %{
    nop %sh{ (printf '
session   = "%s"
client    = "%s"
buffile   = "%s"
version   = %d
method    = "textDocument/hover"
[params.position]
line      = %d
character = %d
' "${kak_session}" "${kak_client}" "${kak_buffile}" "${kak_timestamp}" $(expr ${kak_cursor_line} - 1) $(expr ${kak_cursor_column} - 1) | ${kak_opt_lsp_cmd}) > /dev/null 2>&1 < /dev/null & }
}

def lsp-definition %{
    nop %sh{ (printf '
session   = "%s"
client    = "%s"
buffile   = "%s"
version   = %d
method    = "textDocument/definition"
[params.position]
line      = %d
character = %d
' "${kak_session}" "${kak_client}" "${kak_buffile}" "${kak_timestamp}" $(expr ${kak_cursor_line} - 1) $(expr ${kak_cursor_column} - 1) | ${kak_opt_lsp_cmd}) > /dev/null 2>&1 < /dev/null & }
}

def lsp-did-open %{
    nop %sh{ (printf '
session = "%s"
client  = "%s"
buffile = "%s"
version = %d
method  = "textDocument/didOpen"
[params]
' "${kak_session}" "${kak_client}" "${kak_buffile}" "${kak_timestamp}" | ${kak_opt_lsp_cmd}) > /dev/null 2>&1 < /dev/null & }
}

def lsp-did-close %{
    nop %sh{ (printf '
session = "%s"
client  = "%s"
buffile = "%s"
version = %d
method  = "textDocument/didClose"
[params]
' "${kak_session}" "${kak_client}" "${kak_buffile}" "${kak_timestamp}" | ${kak_opt_lsp_cmd}) > /dev/null 2>&1 < /dev/null & }
}

def lsp-did-save %{
    nop %sh{ (printf '
session = "%s"
client  = "%s"
buffile = "%s"
version = %d
method  = "textDocument/didSave"
[params]
' "${kak_session}" "${kak_client}" "${kak_buffile}" "${kak_timestamp}" | ${kak_opt_lsp_cmd}) > /dev/null 2>&1 < /dev/null & }
}

def lsp-exit %{
    nop %sh{ (printf '
session = "%s"
client  = "%s"
buffile = "%s"
version = %d
method  = "exit"
[params]
' "${kak_session}" "${kak_client}" "${kak_buffile}" "${kak_timestamp}" | ${kak_opt_lsp_cmd}) > /dev/null 2>&1 < /dev/null & }
}

def lsp-enable %{
    set global completers "option=lsp_completions:%opt{completers}"
    add-highlighter global/ ranges lsp_errors
    add-highlighter global/ ranges cquery_semhl

    map global goto d '<esc>:lsp-definition<ret>' -docstring 'definition'

    hook -group lsp global BufCreate .* %{
        lsp-did-open
    }
    hook -group lsp global BufClose .* lsp-did-close
    hook -group lsp global BufWritePost .* lsp-did-save
    hook -group lsp global InsertIdle .* %{
        lsp-did-change
        lsp-completion
    }
    hook -group lsp global NormalIdle .* %{
        lsp-did-change
        lsp-hover
    }
    hook -group lsp global KakEnd .* %{
        lsp-exit
    }
}

