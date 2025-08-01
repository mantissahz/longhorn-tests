*** Settings ***
Documentation    Backup Keywords

Library    ../libs/keywords/common_keywords.py
Library    ../libs/keywords/backup_keywords.py

*** Keywords ***
Create backup ${backup_id} for volume ${volume_id}
    [Arguments]    &{config}
    ${volume_name} =    generate_name_with_suffix    volume    ${volume_id}
    create_backup    ${volume_name}    ${backup_id}    &{config}

Create backup ${backup_id} for ${workload_kind} ${workload_id} volume
    ${backup_id}=  Convert To String  ${backup_id}
    ${workload_name}=   generate_name_with_suffix    ${workload_kind}    ${workload_id}
    ${volume_name}=    get_workload_volume_name    ${workload_name}
    create_backup  ${volume_name}  ${backup_id}

Create error backup for volume ${volume_id}
    ${volume_name} =    generate_name_with_suffix    volume    ${volume_id}
    create_error_backup    ${volume_name}

Verify backup list contains errors for volume ${volume_id}
    ${volume_name} =    generate_name_with_suffix    volume    ${volume_id}
    verify_errors    ${volume_name}

Verify backup list contains no error for volume ${volume_id}
    ${volume_name} =    generate_name_with_suffix    volume    ${volume_id}
    verify_no_error    ${volume_name}

Verify backup list contains backup no error for ${workload_kind} ${workload_id} volume 
    ${workload_name} =   generate_name_with_suffix    ${workload_kind}    ${workload_id}
    ${volume_name} =    get_workload_volume_name    ${workload_name}
    verify_no_error    ${volume_name}

Verify backup list contains backup ${backup_id} of volume ${volume_id}
    ${volume_name} =    generate_name_with_suffix    volume    ${volume_id}
    ${backup} =    get_backup_name    ${backup_id}    ${volume_name}
    Should Not Be Equal    ${backup}    ${None}

Verify backup list contains backup ${backup_id} of ${workload_kind} ${workload_id} volume
    ${backup_id}=  Convert To String  ${backup_id}
    ${workload_name}=   generate_name_with_suffix    ${workload_kind}    ${workload_id}
    ${volume_name}=    get_workload_volume_name    ${workload_name}
    ${backup}=    get_backup_name    ${backup_id}    ${volume_name}
    Should Not Be Equal    ${backup}    ${None}

Delete backup volume ${volume_id}
    ${volume_name} =    generate_name_with_suffix    volume    ${volume_id}
    delete_backup_volume    ${volume_name}

Check volume ${volume_id} data is backup ${backup_id} of volume ${source_volume_id}
    ${volume_name} =    generate_name_with_suffix    volume    ${volume_id}
    ${source_volume_name} =    generate_name_with_suffix    volume    ${source_volume_id}
    ${backup_name} =    get_backup_name    ${backup_id}    ${source_volume_name}
    check_restored_volume_checksum    ${volume_name}    ${backup_name}

Check backup synced from backupstore
    assert_all_backups_before_uninstall_exist    ${backups_before_uninstall}

Volume ${volume_id} backup ${backup_id} should be able to create
    Create backup ${backup_id} for volume ${volume_id}
    Verify backup list contains no error for volume ${volume_id}
    Verify backup list contains backup ${backup_id} of volume ${volume_id}

Check snapshot for backup ${backup_id} of volume ${volume_id} exists ${exists}
    ${volume_name} =    generate_name_with_suffix    volume    ${volume_id}
    check_snapshot_exists_for_backup    ${volume_name}    ${backup_id}    ${exists}

Wait for backup associated with csi volume snapshot ${csi_volume_snapshot_id} of ${workload_kind} ${workload_id} to be created
    ${csi_volume_snapshot_name} =    generate_name_with_suffix    csi-volume-snapshot    ${csi_volume_snapshot_id}
    ${longhorn_snapshot_name} =    get_longhorn_snapshot_name_associated_with_csi_volume_snapshot    ${csi_volume_snapshot_name}
    ${workload_name} =   generate_name_with_suffix    ${workload_kind}    ${workload_id}
    ${volume_name} =    get_workload_volume_name    ${workload_name}
    wait_for_snapshot_backup_to_be_created    ${volume_name}    ${longhorn_snapshot_name}

Wait for backup associated with csi volume snapshot ${csi_volume_snapshot_id} of ${workload_kind} ${workload_id} to be deleted
    ${csi_volume_snapshot_name} =    generate_name_with_suffix    csi-volume-snapshot    ${csi_volume_snapshot_id}
    ${workload_name} =   generate_name_with_suffix    ${workload_kind}    ${workload_id}
    ${volume_name} =    get_workload_volume_name    ${workload_name}
    wait_for_snapshot_backup_to_be_deleted    ${volume_name}    ${longhorn_snapshot_name}

Backup associated with csi volume snapshot ${csi_volume_snapshot_id} of ${workload_kind} ${workload_id} should still exist
    ${csi_volume_snapshot_name} =    generate_name_with_suffix    csi-volume-snapshot    ${csi_volume_snapshot_id}
    ${workload_name} =   generate_name_with_suffix    ${workload_kind}    ${workload_id}
    ${volume_name} =    get_workload_volume_name    ${workload_name}
    wait_for_snapshot_backup_to_be_created    ${volume_name}    ${longhorn_snapshot_name}
