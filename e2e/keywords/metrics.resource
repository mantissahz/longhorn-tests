*** Settings ***
Documentation       Metrics Keywords

Library             ../libs/keywords/metrics_keywords.py

*** Keywords ***
Check if nodes are under memory pressure
    ${worker_nodes} =    get_worker_nodes
    FOR    ${worker_node}    IN    @{worker_nodes}
        get_node_memory_usage_in_percentage    ${worker_node}
        check_if_node_under_memory_pressure    ${worker_node}
    END
