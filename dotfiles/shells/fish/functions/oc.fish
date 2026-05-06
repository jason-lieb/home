function oc
    env HTTPS_PROXY=http://127.0.0.1:9009 HTTP_PROXY=http://127.0.0.1:9009 NO_PROXY=localhost,127.0.0.1 opencode $argv
end
