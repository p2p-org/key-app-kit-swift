#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

char *transfer_spl_token(const char *relay_program_id,
                         const char *sender_token_account_address,
                         const char *recipient_address,
                         const char *token_mint_address,
                         const char *authority_address,
                         uint64_t amount,
                         uint8_t decimals,
                         uint64_t fee_amount,
                         const char *blockhash,
                         uint64_t minimum_token_account_balance,
                         bool needs_create_recipient_token_account,
                         const char *fee_payer_address);

char *greet(const char *name);
