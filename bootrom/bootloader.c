#include <stddef.h>
#include <stdint.h>

#define ED25519_NO_SEED 1
#include "sha3/sha3.h"
/* Adopted from https://github.com/orlp/ed25519
  provides:
  - void ed25519_create_keypair(t_pubkey *public_key, t_privkey *private_key, t_seed *seed);
  - void ed25519_sign(t_signature *signature,
                      const unsigned uint8_t *message,
                      size_t message_len,
                      t_pubkey *public_key,
                      t_privkey *private_key);
*/

#include "ed25519/ed25519.h"
/* adopted from
  provides:
  - int sha3_init(sha3_context * md);
  - int sha3_update(sha3_context * md, const unsigned char *in, size_t inlen);
  - int sha3_final(sha3_context * md, unsigned char *out);
  types: sha3_context
*/

#include "string.h"
/*
  provides memcpy, memset
*/


typedef unsigned char byte;

// Sanctum header fields in DRAM
extern byte sanctum_dev_public_key[32];
extern byte sanctum_dev_secret_key[64];
unsigned int sanctum_sm_size = 0x1ff000;
extern byte sanctum_sm_hash[64];
extern byte sanctum_sm_public_key[32];
extern byte sanctum_sm_secret_key[64];
extern byte sanctum_sm_signature[64];
#define DRAM_BASE 0xA0000000

/* Update this to generate valid entropy for target platform*/
inline byte random_byte(unsigned int i) {
#warning Bootloader does not have entropy source, keys are for TESTING ONLY
  return 0xac + (0xdd ^ i);
}

// TODO: Change the following code according to your implementation
#define UART0_BASE      0x10013000
#define GPIO_BASE       0x10012000
#define UART_REG_TXFIFO		0
#define UART_REG_RXFIFO		1
#define UART_REG_TXCTRL		2
#define UART_REG_RXCTRL		3
#define UART_REG_DIV		  6
#define UART_TXEN		      0x1
#define UART_RXEN		      0x1
#define UART_TXFIFO_FULL        (1<<31)

#define GPIO_INPUT_VAL      (0x00>>2)
#define GPIO_INPUT_EN       (0x04>>2)
#define GPIO_OUTPUT_EN      (0x08>>2)
#define GPIO_OUTPUT_VAL     (0x0C>>2)
#define GPIO_PULLUP_EN      (0x10>>2)
#define GPIO_DRIVE          (0x14>>2)
#define GPIO_RISE_IE        (0x18>>2)
#define GPIO_RISE_IP        (0x1C>>2)
#define GPIO_FALL_IE        (0x20>>2)
#define GPIO_FALL_IP        (0x24>>2)
#define GPIO_HIGH_IE        (0x28>>2)
#define GPIO_HIGH_IP        (0x2C>>2)
#define GPIO_LOW_IE         (0x30>>2)
#define GPIO_LOW_IP         (0x34>>2)
#define GPIO_IOF_EN         (0x38>>2)
#define GPIO_IOF_SEL        (0x3C>>2)
#define GPIO_OUTPUT_XOR     (0x40>>2)

#define IOF0_UART0_MASK     (0x00030000)

#define SYS_BAUDRATE        57600

volatile uint32_t* uart = (uint32_t *)UART0_BASE;
volatile uint32_t* gpio = (uint32_t *)GPIO_BASE;

#define TIMER_REG           (0x02000000)
#define CPU_CLK             8000000

#define __STR(s)                #s
#define STRINGIFY(s)            __STR(s)
#define __RV_CSR_READ(csr)                                      \
    ({                                                          \
        register unsigned long __v;                             \
        __asm volatile("csrr %0, " STRINGIFY(csr)               \
                     : "=r"(__v)                                \
                     :                                          \
                     : "memory");                               \
        __v;                                                    \
    })

#define GET_TIMERCOUNT()    (*(uint32_t *)TIMER_REG)
#define GET_TIMERFREQ()     (32768)
#define RDCYCLE()           __RV_CSR_READ(mcycle)
#define ENABLE_COUNTER()    __asm volatile("csrci 0x320, 0x5")

volatile uint32_t cpuclk = CPU_CLK;

uint32_t measure_cpu_freq(uint32_t n)
{
  uint32_t start_mcycle, delta_mcycle;
  uint32_t start_mtime, delta_mtime;
  uint32_t mtime_freq = GET_TIMERFREQ();

  // Don't start measuruing until we see an mtime tick
  uint32_t tmp = (uint32_t)GET_TIMERCOUNT();
  do {
      start_mtime = (uint32_t)GET_TIMERCOUNT();
      start_mcycle = RDCYCLE();
  } while (start_mtime == tmp);

  do {
      delta_mtime = (uint32_t)GET_TIMERCOUNT() - start_mtime;
      delta_mcycle = RDCYCLE() - start_mcycle;
  } while (delta_mtime < n);

  return (delta_mcycle / delta_mtime) * mtime_freq
          + ((delta_mcycle % delta_mtime) * mtime_freq) / delta_mtime;
}

uint32_t get_cpu_freq()
{
    uint32_t cpu_freq;

    ENABLE_COUNTER();

    // warm up
    measure_cpu_freq(1);
    // measure for real
    cpu_freq = measure_cpu_freq(100);

    return cpu_freq;
}

void hw_init(void)
{
  cpuclk = get_cpu_freq();
  uart = (uint32_t *)UART0_BASE;
  gpio = (uint32_t *)GPIO_BASE;

  uart[UART_REG_TXCTRL] = UART_TXEN;
  uart[UART_REG_RXCTRL] = UART_RXEN;
  uart[UART_REG_DIV] = cpuclk / SYS_BAUDRATE; // 8M, 57600bps

  gpio[GPIO_IOF_SEL] &= ~IOF0_UART0_MASK;
  gpio[GPIO_IOF_EN] |= IOF0_UART0_MASK;
}

void uartputchar(char dat)
{
  while(uart[UART_REG_TXFIFO] & UART_TXFIFO_FULL);
  uart[UART_REG_TXFIFO] = dat;
}

void uartputstr(const char *str)
{
  for (int i = 0; str[i] != '\0'; i ++) {
    uartputchar(str[i]);
  }
}

#define HWINIT()   hw_init()

#define DBGPUTS(str)   uartputstr((str))

void bootloader() {
	//*sanctum_sm_size = 0x200;
  // Reserve stack space for secrets
  byte scratchpad[128];
  sha3_ctx_t hash_ctx;

  HWINIT();
  // TODO: on real device, copy boot image from memory. In simulator, HTIF writes boot image
  // ... SD card to beginning of memory.
  // sd_init();
  // sd_read_from_start(DRAM, 1024);

  /* Gathering high quality entropy during boot on embedded devices is
   * a hard problem. Platforms taking security seriously must provide
   * a high quality entropy source available in hardware. Platforms
   * that do not provide such a source must gather their own
   * entropy. See the Keystone documentation for further
   * discussion. For testing purposes, we have no entropy generation.
  */
  DBGPUTS("Executing bootrom\r\n");

  // Create a random seed for keys and nonces from TRNG
  for (unsigned int i=0; i<32; i++) {
    scratchpad[i] = random_byte(i);
  }

  /* On a real device, the platform must provide a secure root device
     keystore. For testing purposes we hardcode a known private/public
     keypair */
  // TEST Device key
  #include "use_test_keys.h"
  
  // Derive {SK_D, PK_D} (device keys) from a 32 B random seed
  //ed25519_create_keypair(sanctum_dev_public_key, sanctum_dev_secret_key, scratchpad);
  DBGPUTS("Measure Secure Monitor\r\n");
  // Measure SM
  sha3_init(&hash_ctx, 64);
  sha3_update(&hash_ctx, (void*)DRAM_BASE, sanctum_sm_size);
  sha3_final(sanctum_sm_hash, &hash_ctx);

  DBGPUTS("Combine SK_D and H_SM via a hash\r\n");

  // Combine SK_D and H_SM via a hash
  // sm_key_seed <-- H(SK_D, H_SM), truncate to 32B
  sha3_init(&hash_ctx, 64);
  sha3_update(&hash_ctx, sanctum_dev_secret_key, sizeof(*sanctum_dev_secret_key));
  sha3_update(&hash_ctx, sanctum_sm_hash, sizeof(*sanctum_sm_hash));
  sha3_final(scratchpad, &hash_ctx);
  // Derive {SK_D, PK_D} (device keys) from the first 32 B of the hash (NIST endorses SHA512 truncation as safe)
  ed25519_create_keypair(sanctum_sm_public_key, sanctum_sm_secret_key, scratchpad);

  DBGPUTS("Endorse the SM\r\n");

  // Endorse the SM
  memcpy(scratchpad, sanctum_sm_hash, 64);
  memcpy(scratchpad + 64, sanctum_sm_public_key, 32);
  // Sign (H_SM, PK_SM) with SK_D
  ed25519_sign(sanctum_sm_signature, scratchpad, 64 + 32, sanctum_dev_public_key, sanctum_dev_secret_key);

  DBGPUTS("Clean up\r\n");

  // Clean up
  // Erase SK_D
  memset((void*)sanctum_dev_secret_key, 0, sizeof(*sanctum_sm_secret_key));
  
  DBGPUTS("Finish\r\n");

  // caller will clean core state and memory (including the stack), and boot.
  return;
}
