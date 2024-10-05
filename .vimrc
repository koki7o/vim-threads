set number
set relativenumber
set tabstop=4
set shiftwidth=4
set autoindent
set mouse=a
syntax on
colorscheme vimvscode

function! UrlEncode(str)
  return substitute(a:str, '[^A-Za-z0-9_-]', '\="%".printf("%02X", char2nr(submatch(0)))', 'g')
endfunction

function! PostToThreads()
  " Get the text for the post from the current buffer
  let text = join(getline(1, '$'), "\n")

  " URL encode the text
  let encoded_text = UrlEncode(text)

  " Your Threads API credentials and user ID
  let access_token = 'THREADS_ACCESS_TOKEN'
  let user_id = 'THREADS_USER_ID'

  " Step 1: Create the media container
  let create_command = 'curl -s -X POST "https://graph.threads.net/v1.0/' . user_id . '/threads?media_type=TEXT&text=' . encoded_text . '&access_token=' . access_token . '"'
  echo "Executing command: " . create_command
  let create_response = system(create_command)
  echo "Create response: " . create_response
  let container_id = matchstr(create_response, '"id"\s*:\s*"\zs[^"]\+\ze"')

  if empty(container_id)
    let error_message = matchstr(create_response, '"message"\s*:\s*"\zs[^"]\+\ze"')
    let error_type = matchstr(create_response, '"type"\s*:\s*"\zs[^"]\+\ze"')
    if empty(error_message) && empty(error_type)
      echoerr "Failed to create media container. Full response: " . create_response
    else
      echoerr "Failed to create media container. Error type: " . error_type . ", Message: " . error_message
    endif
    return
  endif

  " Wait for 30 seconds (recommended by the API documentation)
  echo "Waiting 30 seconds before publishing..."
  sleep 30

  " Step 2: Publish the container
  let publish_command = 'curl -s -X POST "https://graph.threads.net/v1.0/' . user_id . '/threads_publish?creation_id=' . container_id . '&access_token=' . access_token . '"'
  echo "Executing command: " . publish_command
  let publish_response = system(publish_command)
  echo "Publish response: " . publish_response
  let post_id = matchstr(publish_response, '"id"\s*:\s*"\zs[^"]\+\ze"')

  if empty(post_id)
    let error_message = matchstr(publish_response, '"message"\s*:\s*"\zs[^"]\+\ze"')
    let error_type = matchstr(publish_response, '"type"\s*:\s*"\zs[^"]\+\ze"')
    if empty(error_message) && empty(error_type)
      echoerr "Failed to publish post. Full response: " . publish_response
    else
      echoerr "Failed to publish post. Error type: " . error_type . ", Message: " . error_message
    endif
  else
    echo "Post published successfully! Post ID: " . post_id
  endif
endfunction

" Command to call the function
command! ThreadsPost call PostToThreads()
