-- Process container logs: extract info from filepath and resolve container name
-- Expected path: /home/<user>/.local/share/nerdctl/<namespace_id>/containers/default/<container_id>/<container_id>-json.log
-- Container names are resolved via symlinks in /home/<user>/.local/share/nerdctl/<namespace_id>/default/

function process_container_logs(tag, timestamp, record)
    local filepath = record["filepath"]

    if filepath then
        -- Extract user, namespace_id, and container_id from the path
        -- Pattern: /home/<user>/.local/share/nerdctl/<namespace_id>/containers/default/<container_id>/<container_id>-json.log
        local container_user, namespace_id, container_id = filepath:match(
            "/home/([^/]+)/%.local/share/nerdctl/([^/]+)/containers/default/([^/]+)/")

        if container_user and namespace_id and container_id then
            record["container_user"] = container_user
            record["container_id"] = container_id:sub(1, 12) -- Use short container ID

            -- Resolve container name by checking symlinks in the default directory
            -- The default directory contains symlinks: container_name -> ../containers/default/<container_id>
            local default_dir = string.format("/home/%s/.local/share/nerdctl/%s/default",
                container_user, namespace_id)

            local container_name = "unknown"

            -- Read directory and check symlinks
            local handle = io.popen(string.format("ls -1 '%s' 2>/dev/null", default_dir))
            if handle then
                for name in handle:lines() do
                    local symlink_path = string.format("%s/%s", default_dir, name)
                    local target_handle = io.popen(string.format("readlink '%s' 2>/dev/null", symlink_path))
                    if target_handle then
                        local target = target_handle:read("*line")
                        target_handle:close()

                        -- Check if symlink points to our container_id
                        if target and target:match(container_id) then
                            container_name = name
                            break
                        end
                    end
                end
                handle:close()
            end

            -- Fallback: try reading hostname file
            if container_name == "unknown" then
                local hostname_path = string.format("/home/%s/.local/share/nerdctl/%s/containers/default/%s/hostname",
                    container_user, namespace_id, container_id)
                local file = io.open(hostname_path, "r")
                if file then
                    local hostname = file:read("*line")
                    file:close()
                    if hostname and hostname ~= "" then
                        container_name = hostname:gsub("^%s*(.-)%s*$", "%1") -- trim whitespace
                    end
                end
            end

            record["container_name"] = container_name
        else
            record["container_name"] = "unknown"
            record["container_id"] = "unknown"
        end

        -- Remove the filepath as it's no longer needed
        record["filepath"] = nil
    else
        record["container_name"] = "unknown"
        record["container_id"] = "unknown"
    end

    return 1, timestamp, record
end
