*** Settings ***
Documentation    Negative Test Cases

Test Tags    node-reboot    negative

Resource    ../keywords/variables.resource
Resource    ../keywords/sharemanager.resource
Resource    ../keywords/common.resource
Resource    ../keywords/deployment.resource
Resource    ../keywords/longhorn.resource
Resource    ../keywords/host.resource
Resource    ../keywords/storageclass.resource
Resource    ../keywords/persistentvolumeclaim.resource
Resource    ../keywords/recurringjob.resource
Resource    ../keywords/statefulset.resource
Resource    ../keywords/volume.resource
Resource    ../keywords/workload.resource
Resource    ../keywords/setting.resource

Test Setup    Set up test environment
Test Teardown    Cleanup test resources

*** Test Cases ***
Shutdown Volume Node And Test Auto Reattach To A New Node
    Given Set setting node-down-pod-deletion-policy to delete-both-statefulset-and-deployment-pod
    And Create storageclass longhorn-test with    dataEngine=${DATA_ENGINE}
    And Create persistentvolumeclaim 0    volume_type=RWO    sc_name=longhorn-test
    And Create persistentvolumeclaim 1    volume_type=RWX    sc_name=longhorn-test

    And Create deployment 0 with persistentvolumeclaim 0
    And Create deployment 1 with persistentvolumeclaim 1

    And Wait for volume of deployment 0 healthy
    And Wait for volume of deployment 1 healthy

    And Write 100 MB data to file data.bin in deployment 0
    And Write 100 MB data to file data.bin in deployment 1

    When Power off volume node of deployment 0 without waiting
    And Power off volume node of deployment 1 without waiting

    Then Wait for sharemanager pod of deployment 1 restart
    And Wait for sharemanager pod of deployment 1 running

    And Wait for volume of deployment 0 attached and degraded
    And Wait for volume of deployment 1 attached and degraded

    And Wait for workloads pods stable
        ...    deployment 0    deployment 1

    And Check deployment 0 data in file data.bin is intact
    And Check deployment 1 data in file data.bin is intact
    And Check deployment 0 works
    And Check deployment 1 works

    And Power on off nodes

Reboot Node One By One While Workload Heavy Writing
    [Tags]    reboot
    Given Set setting rwx-volume-fast-failover to ${RWX_VOLUME_FAST_FAILOVER}
    And Create storageclass strict-local with    numberOfReplicas=1    dataLocality=strict-local    dataEngine=${DATA_ENGINE}
    And Create storageclass longhorn-test with    dataEngine=${DATA_ENGINE}
    And Create persistentvolumeclaim 0    volume_type=RWO    sc_name=longhorn-test
    And Create persistentvolumeclaim 1    volume_type=RWX    sc_name=longhorn-test
    And Create persistentvolumeclaim 2    volume_type=RWO    sc_name=strict-local

    And Create deployment 0 with persistentvolumeclaim 0
    And Create deployment 1 with persistentvolumeclaim 1
    And Create deployment 2 with persistentvolumeclaim 2

    And Create statefulset 0 using RWO volume with longhorn-test storageclass
    And Create statefulset 1 using RWX volume with longhorn-test storageclass
    And Create statefulset 2 using RWO volume with strict-local storageclass

    FOR    ${i}    IN RANGE    ${LOOP_COUNT}
        And Keep writing data to pod of deployment 0
        And Keep writing data to pod of deployment 1
        And Keep writing data to pod of deployment 2
        And Keep writing data to pod of statefulset 0
        And Keep writing data to pod of statefulset 1
        And Keep writing data to pod of statefulset 2

        When Reboot node 0
        And Reboot node 1
        And Reboot node 2
        And Wait for longhorn ready
        And Wait for workloads pods stable
        ...    deployment 0    deployment 1    deployment 2
        ...    statefulset 0    statefulset 1    statefulset 2

        Then Check deployment 0 works
        And Check deployment 1 works
        And Check deployment 2 works
        And Check statefulset 0 works
        And Check statefulset 1 works
        And Check statefulset 2 works
    END

Power Off Node One By One For More Than Pod Eviction Timeout While Workload Heavy Writing
    [Tags]    reboot
    Given Set setting rwx-volume-fast-failover to ${RWX_VOLUME_FAST_FAILOVER}
    And Create storageclass strict-local with    numberOfReplicas=1    dataLocality=strict-local    dataEngine=${DATA_ENGINE}
    And Create storageclass longhorn-test with    dataEngine=${DATA_ENGINE}
    And Create persistentvolumeclaim 0    volume_type=RWO    sc_name=longhorn-test
    And Create persistentvolumeclaim 1    volume_type=RWX    sc_name=longhorn-test
    And Create persistentvolumeclaim 2    volume_type=RWO    sc_name=strict-local

    And Create deployment 0 with persistentvolumeclaim 0
    And Create deployment 1 with persistentvolumeclaim 1
    And Create deployment 2 with persistentvolumeclaim 2

    And Create statefulset 0 using RWO volume with longhorn-test storageclass
    And Create statefulset 1 using RWX volume with longhorn-test storageclass
    And Create statefulset 2 using RWO volume with strict-local storageclass

    FOR    ${i}    IN RANGE    ${LOOP_COUNT}
        And Keep writing data to pod of deployment 0
        And Keep writing data to pod of deployment 1
        And Keep writing data to pod of deployment 2
        And Keep writing data to pod of statefulset 0
        And Keep writing data to pod of statefulset 1
        And Keep writing data to pod of statefulset 2

        When Power off node 0 for 6 mins
        And Power off node 1 for 6 mins
        And Power off node 2 for 6 mins
        And Wait for longhorn ready
        And Wait for workloads pods stable
        ...    deployment 0    deployment 1    deployment 2
        ...    statefulset 0    statefulset 1    statefulset 2

        Then Check deployment 0 works
        And Check deployment 1 works
        And Check deployment 2 works
        And Check statefulset 0 works
        And Check statefulset 1 works
        And Check statefulset 2 works
    END

Reboot All Worker Nodes While Workload Heavy Writing
    [Tags]    reboot
    Given Set setting rwx-volume-fast-failover to ${RWX_VOLUME_FAST_FAILOVER}
    And Create storageclass strict-local with    numberOfReplicas=1    dataLocality=strict-local    dataEngine=${DATA_ENGINE}
    And Create storageclass longhorn-test with    dataEngine=${DATA_ENGINE}
    And Create persistentvolumeclaim 0    volume_type=RWO    sc_name=longhorn-test
    And Create persistentvolumeclaim 1    volume_type=RWX    sc_name=longhorn-test
    And Create persistentvolumeclaim 2    volume_type=RWO    sc_name=strict-local

    And Create deployment 0 with persistentvolumeclaim 0
    And Create deployment 1 with persistentvolumeclaim 1
    And Create deployment 2 with persistentvolumeclaim 2

    And Create statefulset 0 using RWO volume with longhorn-test storageclass
    And Create statefulset 1 using RWX volume with longhorn-test storageclass
    And Create statefulset 2 using RWO volume with strict-local storageclass

    FOR    ${i}    IN RANGE    ${LOOP_COUNT}
        And Keep writing data to pod of deployment 0
        And Keep writing data to pod of deployment 1
        And Keep writing data to pod of deployment 2
        And Keep writing data to pod of statefulset 0
        And Keep writing data to pod of statefulset 1
        And Keep writing data to pod of statefulset 2

        When Restart all worker nodes
        And Wait for longhorn ready
        And Wait for workloads pods stable
        ...    deployment 0    deployment 1    deployment 2
        ...    statefulset 0    statefulset 1    statefulset 2

        Then Check deployment 0 works
        And Check deployment 1 works
        And Check deployment 2 works
        And Check statefulset 0 works
        And Check statefulset 1 works
        And Check statefulset 2 works
    END

Power Off All Worker Nodes For More Than Pod Eviction Timeout While Workload Heavy Writing
    [Tags]    reboot
    Given Set setting rwx-volume-fast-failover to ${RWX_VOLUME_FAST_FAILOVER}
    And Create storageclass strict-local with    numberOfReplicas=1    dataLocality=strict-local    dataEngine=${DATA_ENGINE}
    And Create storageclass longhorn-test with    dataEngine=${DATA_ENGINE}
    And Create persistentvolumeclaim 0    volume_type=RWO    sc_name=longhorn-test
    And Create persistentvolumeclaim 1    volume_type=RWX    sc_name=longhorn-test
    And Create persistentvolumeclaim 2    volume_type=RWO    sc_name=strict-local

    And Create deployment 0 with persistentvolumeclaim 0
    And Create deployment 1 with persistentvolumeclaim 1
    And Create deployment 2 with persistentvolumeclaim 2

    And Create statefulset 0 using RWO volume with longhorn-test storageclass
    And Create statefulset 1 using RWX volume with longhorn-test storageclass
    And Create statefulset 2 using RWO volume with strict-local storageclass

    FOR    ${i}    IN RANGE    ${LOOP_COUNT}
        And Keep writing data to pod of deployment 0
        And Keep writing data to pod of deployment 1
        And Keep writing data to pod of deployment 2
        And Keep writing data to pod of statefulset 0
        And Keep writing data to pod of statefulset 1
        And Keep writing data to pod of statefulset 2

        When Power off all worker nodes for 6 mins
        And Wait for longhorn ready
        And Wait for workloads pods stable
        ...    deployment 0    deployment 1    deployment 2
        ...    statefulset 0    statefulset 1    statefulset 2

        Then Check deployment 0 works
        And Check deployment 1 works
        And Check deployment 2 works
        And Check statefulset 0 works
        And Check statefulset 1 works
        And Check statefulset 2 works
    END

Reboot Volume Node While Workload Heavy Writing
    [Tags]    reboot
    Given Set setting rwx-volume-fast-failover to ${RWX_VOLUME_FAST_FAILOVER}
    And Create storageclass longhorn-test with    dataEngine=${DATA_ENGINE}
    And Create statefulset 0 using RWO volume with longhorn-test storageclass
    And Create statefulset 1 using RWX volume with longhorn-test storageclass
    FOR    ${i}    IN RANGE    ${LOOP_COUNT}
        And Keep writing data to pod of statefulset 0
        When Reboot volume node of statefulset 0
        And Wait for volume of statefulset 0 healthy
        And Wait for statefulset 0 pods stable
        Then Check statefulset 0 works

        And Keep writing data to pod of statefulset 1
        When Reboot volume node of statefulset 1
        And Wait for volume of statefulset 1 healthy
        And Wait for statefulset 1 pods stable
        Then Check statefulset 1 works
    END

Power Off Volume Node For More Than Pod Eviction Timeout While Workload Heavy Writing
    [Tags]    reboot
    Given Set setting rwx-volume-fast-failover to ${RWX_VOLUME_FAST_FAILOVER}
    And Create storageclass longhorn-test with    dataEngine=${DATA_ENGINE}
    And Create statefulset 0 using RWO volume with longhorn-test storageclass
    And Create statefulset 1 using RWX volume with longhorn-test storageclass
    FOR    ${i}    IN RANGE    ${LOOP_COUNT}
        And Keep writing data to pod of statefulset 0
        When Power off volume node of statefulset 0 for 6 minutes
        And Wait for volume of statefulset 0 healthy
        And Wait for statefulset 0 pods stable
        Then Check statefulset 0 works

        And Keep writing data to pod of statefulset 1
        When Power off volume node of statefulset 1 for 6 minutes
        And Wait for volume of statefulset 1 healthy
        And Wait for statefulset 1 pods stable
        Then Check statefulset 1 works
    END

Reboot Volume Node While Heavy Writing And Recurring Jobs Exist
    [Tags]    recurring_job
    Given Create volume 0 with    size=2Gi    numberOfReplicas=1    dataEngine=${DATA_ENGINE}
    And Create volume 1 with    size=2Gi    numberOfReplicas=3    dataEngine=${DATA_ENGINE}
    And Create volume 2 with    size=2Gi    numberOfReplicas=3    accessMode=RWX    dataEngine=${DATA_ENGINE}
    And Attach volume 0
    And Attach volume 1
    And Attach volume 2
    And Keep writing data to volume 0
    And Keep writing data to volume 1
    And Keep writing data to volume 2
    And Create snapshot and backup recurringjob for volume 0
    And Create snapshot and backup recurringjob for volume 1
    And Create snapshot and backup recurringjob for volume 2

    FOR    ${i}    IN RANGE    ${LOOP_COUNT}
        When Reboot volume 0 volume node
        And Wait for volume 0 healthy

        Then Check recurringjobs for volume 0 work
        And Check recurringjobs for volume 1 work
        And Check recurringjobs for volume 2 work
        And Check volume 0 works
        And Check volume 1 works
        And Check volume 2 works
    END

Physical Node Reboot With Attached Deployment
    Given Create storageclass longhorn-test with    dataEngine=${DATA_ENGINE}
    And Create persistentvolumeclaim 0    volume_type=${VOLUME_TYPE}    sc_name=longhorn-test
    And Create deployment 0 with persistentvolumeclaim 0
    And Write 100 MB data to file data in deployment 0

    And Reboot volume node of deployment 0
    And Wait for deployment 0 pods stable
    Then Check deployment 0 data in file data is intact

Physical Node Reboot With Attached Statefulset
    Given Create storageclass longhorn-test with    dataEngine=${DATA_ENGINE}
    And Create statefulset 0 using ${VOLUME_TYPE} volume with longhorn-test storageclass
    And Write 100 MB data to file data in statefulset 0

    And Reboot volume node of statefulset 0
    And Wait for statefulset 0 pods stable
    Then Check statefulset 0 data in file data is intact

Single Replica Node Down Deletion Policy do-nothing With RWO Volume Replica Locate On Replica Node
    Given Create storageclass longhorn-test with    dataEngine=${DATA_ENGINE}
    And Set setting node-down-pod-deletion-policy to do-nothing
    When Create persistentvolumeclaim 0    volume_type=RWO    sc_name=longhorn-test
    And Create deployment 0 with persistentvolumeclaim 0
    And Wait for volume of deployment 0 healthy
    And Write 100 MB data to file data in deployment 0

    # Delete replicas to have the volume with its only replica located on different nodes.
    And Update volume of deployment 0 replica count to 1
    And Delete replica of deployment 0 volume on replica node
    And Delete replica of deployment 0 volume on volume node
    And Power off volume node of deployment 0
    And Wait for deployment 0 pod stuck in Terminating on the original node

    When Power on off nodes
    And Wait for deployment 0 pods stable
    Then Check deployment 0 data in file data is intact

Single Replica Node Down Deletion Policy do-nothing With RWO Volume Replica Locate On Volume Node
    Given Create storageclass longhorn-test with    dataEngine=${DATA_ENGINE}
    And Set setting node-down-pod-deletion-policy to do-nothing
    When Create persistentvolumeclaim 0    volume_type=RWO    sc_name=longhorn-test
    And Create deployment 0 with persistentvolumeclaim 0
    And Wait for volume of deployment 0 healthy
    And Write 100 MB data to file data in deployment 0

    # Delete replicas to have the volume with its only replica located on the same node.
    And Update volume of deployment 0 replica count to 1
    And Delete replica of deployment 0 volume on all replica node
    And Power off volume node of deployment 0
    And Wait for deployment 0 pod stuck in Terminating on the original node

    When Power on off nodes
    And Wait for deployment 0 pods stable
    Then Check deployment 0 data in file data is intact

Single Replica Node Down Deletion Policy delete-deployment-pod With RWO Volume Replica Locate On Replica Node
    Given Create storageclass longhorn-test with    dataEngine=${DATA_ENGINE}
    And Set setting node-down-pod-deletion-policy to delete-deployment-pod
    When Create persistentvolumeclaim 0    volume_type=RWO    sc_name=longhorn-test
    And Create deployment 0 with persistentvolumeclaim 0
    And Wait for volume of deployment 0 healthy
    And Write 100 MB data to file data in deployment 0

    # Delete replicas to have the volume with its only replica located on different nodes.
    And Update volume of deployment 0 replica count to 1
    And Delete replica of deployment 0 volume on replica node
    And Delete replica of deployment 0 volume on volume node
    And Power off volume node of deployment 0
    Then Wait for volume of deployment 0 attaching

    And Wait for deployment 0 pods stable
    Then Check deployment 0 data in file data is intact
    And Power on off nodes

Single Replica Node Down Deletion Policy delete-deployment-pod With RWO Volume Replica Locate On Volume Node
    Given Create storageclass longhorn-test with    dataEngine=${DATA_ENGINE}
    And Set setting node-down-pod-deletion-policy to delete-deployment-pod
    When Create persistentvolumeclaim 0    volume_type=RWO    sc_name=longhorn-test
    And Create deployment 0 with persistentvolumeclaim 0
    And Wait for volume of deployment 0 healthy
    And Write 100 MB data to file data in deployment 0

    # Delete replicas to have the volume with its only replica located on the same node
    And Update volume of deployment 0 replica count to 1
    And Delete replica of deployment 0 volume on all replica node
    And Power off volume node of deployment 0
    Then Wait for volume of deployment 0 faulted
    And Wait for deployment 0 pod stuck in ContainerCreating on another node

    When Power on off nodes
    And Wait for deployment 0 pods stable
    And Check deployment 0 pod is Running on the original node
    Then Check deployment 0 data in file data is intact

Single Replica Node Down Deletion Policy delete-both-statefulset-and-deployment-pod With RWO Volume Replica Locate On Replica Node
    Given Create storageclass longhorn-test with    dataEngine=${DATA_ENGINE}
    And Set setting node-down-pod-deletion-policy to delete-both-statefulset-and-deployment-pod
    When Create statefulset 0 using RWO volume with longhorn-test storageclass
    And Wait for volume of statefulset 0 healthy
    And Write 100 MB data to file data in statefulset 0

    # Delete replicas to have the volume with its only replica located on different nodes.
    And Update volume of statefulset 0 replica count to 1
    And Delete replica of statefulset 0 volume on replica node
    And Delete replica of statefulset 0 volume on volume node
    And Power off volume node of statefulset 0
    Then Wait for volume of statefulset 0 attaching

    And Wait for statefulset 0 pods stable
    Then Check statefulset 0 data in file data is intact
    And Power on off nodes

Single Replica Node Down Deletion Policy delete-both-statefulset-and-deployment-pod With RWO Volume Replica Locate On Volume Node
    Given Create storageclass longhorn-test with    dataEngine=${DATA_ENGINE}
    And Set setting node-down-pod-deletion-policy to delete-both-statefulset-and-deployment-pod
    When Create statefulset 0 using RWO volume with longhorn-test storageclass
    And Wait for volume of statefulset 0 healthy
    And Write 100 MB data to file data in statefulset 0

    # Delete replicas to have the volume with its only replica located on the same.
    And Update volume of statefulset 0 replica count to 1
    And Delete replica of statefulset 0 volume on all replica node
    And Power off volume node of statefulset 0
    Then Wait for volume of statefulset 0 faulted
    And Wait for statefulset 0 pod stuck in ContainerCreating on another node

    When Power on off nodes
    And Wait for statefulset 0 pods stable
    And Check statefulset 0 pod is Running on the original node
    Then Check statefulset 0 data in file data is intact

Reboot Replica Node While Heavy Writing And Recurring Jobs Exist
    [Tags]    recurring_job
    Given Create volume 0 with    size=2Gi    numberOfReplicas=1    dataEngine=${DATA_ENGINE}
    And Create volume 1 with    size=2Gi    numberOfReplicas=3    dataEngine=${DATA_ENGINE}
    And Create volume 2 with    size=2Gi    numberOfReplicas=3    accessMode=RWX    dataEngine=${DATA_ENGINE}
    And Attach volume 0
    And Attach volume 1
    And Attach volume 2
    And Keep writing data to volume 0
    And Keep writing data to volume 1
    And Keep writing data to volume 2
    And Create snapshot and backup recurringjob for volume 0
    And Create snapshot and backup recurringjob for volume 1
    And Create snapshot and backup recurringjob for volume 2

    FOR    ${i}    IN RANGE    ${LOOP_COUNT}
        When Reboot volume 1 replica node
        And Wait for volume 1 healthy

        Then Check recurringjobs for volume 0 work
        And Check recurringjobs for volume 1 work
        And Check recurringjobs for volume 2 work
        And Check volume 0 works
        And Check volume 1 works
        And Check volume 2 works
    END

Power Off Replica Node Should Not Rebuild New Replica On Same Node
    [Tags]    replica   reboot
    [Documentation]    Ensures that no new replica is created and rebuilt on the
    ...                same node if the node is powered off for a duration longer
    ...                than the replica-replenishment-wait-interval. When the node
    ...                is powered on, the existing replica should be reused.
    ...
    ...                Issue: https://github.com/longhorn/longhorn/issues/1992

    Given Set setting replica-replenishment-wait-interval to 30
    And Set setting replica-soft-anti-affinity to false
    And Create volume 0 with    size=1Gi    numberOfReplicas=3
    And Attach volume 0 to node 0
    And Record volume 0 replica names

    FOR    ${i}    IN RANGE    ${LOOP_COUNT}
        When Power off node 1 for 1 mins
        And Wait for longhorn ready
        And Wait for volume 0 healthy

        Then Check volume 0 replica names are as recorded
    END
