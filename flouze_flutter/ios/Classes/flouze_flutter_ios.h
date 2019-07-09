#ifndef FLOUZE_FLUTTER_RUST_H
#define FLOUZE_FLUTTER_RUST_H

#include <stddef.h>
#include <stdint.h>

void flouze_error_free(char *error);

void* flouze_sled_repository_temporary(char **error);
void* flouze_sled_repository_from_file(const char *path, char **error);
void flouze_sled_repository_destroy(void *repo);

void flouze_sled_repository_add_account(void *repo, const uint8_t *account_data, size_t account_len, char **error);
void flouze_sled_repository_delete_account(void *repo, const uint8_t *account_id, size_t account_id_len, char **error);
void flouze_sled_repository_list_accounts(void *repo, uint8_t **account_list, size_t *account_list_len, char **error);
void flouze_sled_repository_list_transactions(void *repo, const uint8_t *account_id, size_t account_id_len, uint8_t **tx_list, size_t *tx_list_len, char **error);
void flouze_sled_repository_add_transaction(void *repo, const uint8_t *account_id, size_t account_id_len, const uint8_t *tx, size_t tx_len, char **error);
void flouze_sled_repository_get_balance(void *repo, const uint8_t *account_id, size_t account_id_len, uint8_t **balance, size_t *balance_len, char **error);
void* flouze_json_rpc_client_create(const char *url, char **error);
void flouze_json_rpc_client_destroy(void *client);
void flouze_json_rpc_client_create_account(void *client, const uint8_t *account, size_t account_len, char **error);
void flouze_json_rpc_client_get_account_info(void *client, const uint8_t *account_id, size_t account_id_len, uint8_t **account, size_t *account_len, char **error);
void flouze_sync_clone_remote(void *repo, void *client, const uint8_t *account_id, size_t account_id_len, char **error);
void flouze_sync_sync(void *repo, void *client, const uint8_t *account_id, size_t account_id_len, char **error);

#endif // FLOUZE_FLUTTER_RUST_H
