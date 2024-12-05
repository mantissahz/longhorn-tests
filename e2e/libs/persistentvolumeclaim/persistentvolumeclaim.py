import time
import yaml

from strategy import LonghornOperationStrategy

from persistentvolumeclaim.crd import CRD

from kubernetes import client
from kubernetes.client.rest import ApiException

from utility.constant import ANNOT_EXPANDED_SIZE
from utility.constant import LABEL_TEST
from utility.constant import LABEL_TEST_VALUE
from utility.utility import convert_size_to_bytes
from utility.utility import get_retry_count_and_interval
from utility.utility import logging


class PersistentVolumeClaim():

    _strategy = LonghornOperationStrategy.CRD

    def __init__(self):
        if self._strategy == LonghornOperationStrategy.CRD:
            self.claim = CRD()

    def create(self, name, volume_type, sc_name, storage_size="3GiB"):
        storage_size_bytes = convert_size_to_bytes(storage_size)

        filepath = "./templates/workload/pvc.yaml"
        with open(filepath, 'r') as f:
            namespace = 'default'
            manifest_dict = yaml.safe_load(f)

            # correct pvc name
            manifest_dict['metadata']['name'] = name

            # add label
            manifest_dict['metadata']['labels'][LABEL_TEST] = LABEL_TEST_VALUE

            # correct storageclass name
            manifest_dict['spec']['storageClassName'] = sc_name

            # correct storage request
            manifest_dict['spec']['resources']['requests']['storage'] = storage_size_bytes

            # correct access mode`
            if volume_type == 'RWX':
                manifest_dict['spec']['accessModes'][0] = 'ReadWriteMany'
            api = client.CoreV1Api()

            api.create_namespaced_persistent_volume_claim(
                body=manifest_dict,
                namespace=namespace)

    def delete(self, name, namespace='default'):
        api = client.CoreV1Api()
        try:
            api.delete_namespaced_persistent_volume_claim(
                name=name,
                namespace=namespace,
                grace_period_seconds=0)
        except ApiException as e:
            assert e.status == 404

        retry_count, retry_interval = get_retry_count_and_interval()
        deleted = False
        for _ in range(retry_count):
            if not self.is_exist(name, namespace):
                deleted = True
                break
            time.sleep(retry_interval)
        assert deleted

    def is_exist(self, name, namespace='default'):
        exist = False
        api = client.CoreV1Api()
        resp = api.list_namespaced_persistent_volume_claim(namespace=namespace)
        for item in resp.items:
            if item.metadata.name == name:
                exist = True
                break
        return exist

    def get(self, claim_name):
        return self.claim.get(claim_name)

    def list(self, claim_namespace="default", label_selector=None):
        return self.claim.list(claim_namespace=claim_namespace,
                             label_selector=label_selector)

    def set_label(self, claim_name, label_key, label_value, claim_namespace="default"):
        return self.claim.set_label(claim_name, label_key, label_value, claim_namespace=claim_namespace)

    def set_annotation(self, claim_name, annotation_key, annotation_value, claim_namespace="default"):
        return self.claim.set_annotation(claim_name, annotation_key, annotation_value, claim_namespace=claim_namespace)

    def get_annotation_value(self, claim_name, annotation_key):
        return self.claim.get_annotation_value(claim_name, annotation_key)

    def get_volume_name(self, claim_name):
        return self.claim.get_volume_name(claim_name)

    def expand(self, claim_name, size_in_byte):
        pvc = self.claim.get(claim_name)
        current_size = int(pvc.spec.resources.requests['storage'])

        target_size = current_size + size_in_byte
        logging(f"Expanding PVC {claim_name} from {current_size} to {target_size}")
        expanded_size = self.claim.expand(claim_name, target_size)
        self.set_annotation(claim_name, ANNOT_EXPANDED_SIZE, str(expanded_size))
