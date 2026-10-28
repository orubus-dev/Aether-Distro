#define _GNU_SOURCE
#include <assert.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include "aether/aegis.h"

int main(void) {
    assert(aether_aegis_init() == AETHER_OK);

    aether_aegis_rule_t deny_net = {
        .subject_id = 42,
        .resource = AETHER_AEGIS_RESOURCE_NETWORK,
        .decision = AETHER_AEGIS_DECISION_DENY,
        .scope = "example.invalid",
        .priority = 10
    };
    aether_aegis_rule_t allow_net = {
        .subject_id = 42,
        .resource = AETHER_AEGIS_RESOURCE_NETWORK,
        .decision = AETHER_AEGIS_DECISION_ALLOW,
        .scope = "trusted.example",
        .priority = 20
    };

    assert(aether_aegis_add_rule(&deny_net) == AETHER_OK);
    assert(aether_aegis_add_rule(&allow_net) == AETHER_OK);
    assert(aether_aegis_rule_count() == 2);

    aether_aegis_request_t req = {42, AETHER_AEGIS_RESOURCE_NETWORK, "example.invalid"};
    assert(aether_aegis_evaluate(&req) == AETHER_AEGIS_DECISION_DENY);
    req.scope = "trusted.example";
    assert(aether_aegis_evaluate(&req) == AETHER_AEGIS_DECISION_ALLOW);
    req.scope = NULL;
    assert(aether_aegis_evaluate(&req) == AETHER_AEGIS_DECISION_DENY);
    char mutable_scope[] = "mutable.example";
    aether_aegis_rule_t owned = {42,AETHER_AEGIS_RESOURCE_FILESYSTEM,AETHER_AEGIS_DECISION_ALLOW,mutable_scope,5};
    assert(aether_aegis_add_rule(&owned) == AETHER_OK);
    mutable_scope[0] = 'X';
    req = (aether_aegis_request_t){42,AETHER_AEGIS_RESOURCE_FILESYSTEM,"mutable.example"};
    assert(aether_aegis_evaluate(&req) == AETHER_AEGIS_DECISION_ALLOW);
    req.scope = "unlisted.example";
    assert(aether_aegis_evaluate(&req) == AETHER_AEGIS_DECISION_DENY);

    assert(aether_aegis_remove_rule(42, AETHER_AEGIS_RESOURCE_NETWORK, "trusted.example") == AETHER_OK);
    assert(aether_aegis_rule_count() == 2);
    char policy_path[]="/tmp/aether-aegis-XXXXXX";
    int policy_fd=mkstemp(policy_path);
    assert(policy_fd>=0);
    close(policy_fd);
    assert(aether_aegis_save(policy_path)==AETHER_OK);
    aether_aegis_shutdown();
    assert(aether_aegis_load(policy_path)==AETHER_OK);
    assert(aether_aegis_rule_count()==2);
    assert(aether_aegis_evaluate(&(aether_aegis_request_t){42,AETHER_AEGIS_RESOURCE_NETWORK,"example.invalid"})==AETHER_AEGIS_DECISION_DENY);
    assert(unlink(policy_path)==0);
    aether_aegis_shutdown();
    return 0;
}
