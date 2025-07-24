-- Process container logs: extract info from filepath and add container name
-- Expected path: /home/<user>/.local/share/nerdctl/<namespace>/containers/default/<container_id>/<container_id>-json.log

function process_container_logs(tag, timestamp, record)
    local filepath = record["filepath"]

    if filepath then
        -- Extract user, namespace, and container_id from the path
        -- Pattern: /home/<user>/.local/share/nerdctl/<namespace>/containers/default/<container_id>/<container_id>-json.log
        local container_user, container_namespace, container_id = filepath:match(
            "/home/([^/]+)/%.local/share/nerdctl/([^/]+)/containers/default/([^/]+)/")

        if container_user and container_namespace and container_id then
            record["container_user"] = container_user
            record["container_namespace"] = container_namespace
            record["container_id"] = container_id

            -- Now try to read the hostname file to get the container name
            local hostname_path = string.format("/home/%s/.local/share/nerdctl/%s/containers/default/%s/hostname",
                container_user, container_namespace, container_id)

            -- Try to read the hostname file
            local file = io.open(hostname_path, "r")
            if file then
                local container_name = file:read("*line")
                file:close()

                if container_name and container_name ~= "" then
                    record["container_name"] = container_name:gsub("^%s*(.-)%s*$", "%1") -- trim whitespace
                else
                    record["container_name"] = "unknown"
                end
            else
                record["container_name"] = "unknown"
            end
        else
            record["container_name"] = "unknown"
        end

        -- Remove the filepath as it's no longer needed
        record["filepath"] = nil
    else
        record["container_name"] = "unknown"
    end

    return 1, timestamp, record
end
