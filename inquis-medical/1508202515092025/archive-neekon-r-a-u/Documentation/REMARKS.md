# GLOVES MUST COME OFF LEAVING RND LAB, HANDS MUST BE WASHED

# Queue

# common/

## bbstr
<!-- ```
BBStr *bbstr_new(char *s, int len) {
    // Create a new bbstr from an existing string or allocate empty.
    // If len < 0 (BBSTR_COPY) then it will use strlen.
    // Len should NOT include the nul.
    // s can be NULL in which case the new buffer is allocated.
    // and filled with zeros.

    // TODO: Remove?
    stack_check();
```
Peek into stack_check()

```
void bbstr_del(BBStr *bbstr) {
    // Delete a bbstr, decremening the reference count.
    // and deallocating if the reference is zero.

    if (bbstr) {
        bbstr->ref_count--;
        if (bbstr->ref_count <= 0) {
            *bbstr->str = 0; // For good measure
            free(bbstr->str);
            free(bbstr);
            bbstr_global_ref_count--;
        }
    }
}
```
Set a stanard for deallocated pointers, this doesn't make it safer; could corrupt program.

```
BBStr *bbstr_ref(BBStr *bbstr) {
    // Increment the reference count on a bbstr.

    bbstr->ref_count++;
    return bbstr;
}
```
purpose?  -->

```
char *bbstr_malloc_copy(BBStr *bstr) {
    // Return a malloced copy of a bbstr.
    // This is a converter that handles code
    // ?expenting? a plain-old malloc-based string.

    size_t len = strlen(bstr->str) + 1;
    char *buf = (char *)malloc(len);
    inquis_assert(buf != NULL);
    strcpy(buf, bstr->str);
    return buf;
}
```
Trace usage using Doxygen reference tracker. This could be unsafe and/or redundant, pending review of usage.

```
/**
 * @brief Trim whitespace from both ends of a BBStr.
 *
 * @param bbstr Input BBStr to trim.
 * @return A new BBStr with whitespace removed from ends.
 */
BBStr *bbstr_trim(BBStr *bbstr) {
    // Return a new bbstr that has whitspace trimmed on both ends.

    char *lft = bbstr->str;
    while (*lft == ' ' || *lft == '\t' || *lft == '\r' || *lft == '\n') {
        lft++;
    }

    char *rgt = bbstr->str + strlen(bbstr->str) - 1;
    while (rgt > lft && (*rgt == ' ' || *rgt == '\t' || *rgt == '\r' || *rgt == '\n')) {
        rgt--;
    }

    int len = rgt - lft + 1;
    return bbstr_new(lft, len);
}
```
While loop conditions possibly limited in scope. Could protect against buffer overflow/corruption when trimming extremties by excluding alphanumericals instead of case-based statement. Requires revision or removal of method.
Method name, suggest change to bbstr_trim_ends or bbstr_trim_whitespace

```
BBStr *bbstr_left(BBStr *bbstr, unsigned int n) {
    char *lft = bbstr->str;
    int len = 0;
    for (len = 0; len < n && lft[len] != 0; len++)
        ;
    return bbstr_new(lft, len);
}
```
Unsafe, BO risk. Trace references in Doxygen to determine risk as implemented/called. Highly recommend implementing field in BBStr to store size and/or terminate with a more unique character for safety.

```
/**
 * @brief Create a new empty BBStrNode list.
 *
 * @return Pointer to a new BBStrNode with no string attached.
 */
BBStrNode *bbstr_list_new() {
    // Create a new (empy) list of strings.

    BBStrNode *new_bbstr_node = (BBStrNode *)malloc(sizeof(BBStrNode));
    inquis_assert(new_bbstr_node != NULL);
    new_bbstr_node->next = NULL;
    new_bbstr_node->bbstr = NULL;
    bbstrnode_global_ref_count++;
    return new_bbstr_node;
}
```
Why do we need this to be a method? Check usage with doxygen, redundant, suggest removal.

```
BBStr *bbstr_join(BBStrNode *head, char delimiter) {
    // Join a list of strings together as a new bbstr with delimiter.

    // FIND total length
    int len = 0;
    int count = 0;
    for (BBStrNode *curr = head; curr; curr = curr->next) {
        if (curr->bbstr) {
            len += strlen(curr->bbstr->str);
            count++;
        }
    }

    len += (count - 1); // Include interstitial delimiters
    BBStr *new = bbstr_new(NULL, len);

    // COPY into the final
    char *dst = new->str;
    int i = 0;
    for (BBStrNode *curr = head; curr; curr = curr->next) {
        if (curr->bbstr) {
            int len = strlen(curr->bbstr->str);
            memcpy(dst, curr->bbstr->str, len);
            dst += len;
            if (i < count - 1) {
                *dst++ = delimiter;
            }
            i++;
        }
    }
    *dst++ = 0;

    return new;
}
```
Verify safety of "interstitial delimiters"

**Remarks on BBStrNode API:** Not necessary, pending usage review via Doxygen. All functionality should be implemented generically via a list API *if even*. BBStr should be designed to be safe in all data structures; we shouldn't need a dedicated API for BBStr lists if they are safe in any OOP datastructure usage. Review then discuss with team. Also review 'reference counting' functionality as it is used across codebase: why was this feature implemented, and is there an alternative with improved inherent safety.

```
/*
Bare-Bones Str (BBStr) Funcs
----------------------------

This is a bare-bones set of common string functions with reference counting

Example usage:

    // Make a copy of a static string
    BBStr *s = bbstr_new("foo", BBSTR_COPY);
    printf("%s\n", s->str);
    // ... and delete it.
    bbstr_del(s);

    // Make list of strings from statics
    char *strs[] = { "123", "456", "789" };
    BBStrNode *head = bbstr_list_new();
    BBStrNode *curr = head;
    for(int i=0; i<3; i++) {
        BBStr *s = bbstr_new(strs[i], BBSTR_COPY);
        curr = bbstr_list_add(curr, s, 1);
        bbstr_del(s);  // Delete here decrements ref count so the node's memory is still available to the list
    }

    // Traverse the list
    for(BBStrNode *curr=head; curr; curr=curr->next) {
        printf("%s\n", curr->bbstr->str);
    }

    // Get a specific element of the list
    char *elem = bbstr_list_get(head, 0, "");
    assert(0 == strcmp(elem, "123"));

    // Get an element and return default if it doesn't exist
    char *elem = bbstr_list_get(head, 1000, "foo");
    assert(0 == strcmp(elem, "foo"));

    // Delete a list. If it is the owner of the the elements
    // they will also be freed. Otherwise their refernce
    // count will decrement by one.
    bbstr_list_del(head);

    // Delete one element of a list given the previous node
    // (assumes you are traversing).
    BBStrNode *prev = NULL;
    for(BBStrNode *curr=head; curr; ) {
        BBStrNode *next = curr->next;
        if(should_delete(curr)) {
            bbstr_list_del_node(curr, prev);
        }
        else {
            prev = curr;
        }
        curr = next;
    }

    // Make a standalone malloc copy
    char *my_private_copy_of_s = bbstr_malloc_copy(s);
    // Now it can be freed.
    free(my_private_copy_of_s);

    // Split a string...
    BBStr *line = bbstr_new("123, 456, 789", BBSTR_COPY);
    BBStrNode *list = bbstr_split(line, ',', BBSTR_TRIM);
    // ... delete the line now that we don't need it...
    bbstr_del(line);
    // ... and print the elements.
    for(BBStrNode *curr = list; curr; curr = curr->next) {
        printf("%s\n", curr->bbstr->str);
    }

    // Remember to always new and delete.
    // For example, this iS BAD, do NOT do the following!!!
    //   BBStrNode *list = bbstr_split(bbstr_new("123; 456; 789", BBSTR_COPY), ';', BBSTR_TRIM);
    //   bbstr_list_del(list);
    // ... The above code will strand the string that was allocated in the first arg of bbstr_split

    // You can also walk the list as an index although this is inefficeint
    // because it will traverse the list from the head on every call.
    int count = bbstr_list_count(list);
    for(int i=0; i < count; i++) {
        char *s = bbstr_list_get(list, i, NULL);
        printf("list[%d] = %s\n", i, s);
    }

    // ...don't forget to delete lists.
    bbstr_list_del(list);

    // Finally, check that everything was deleted. These should both be zeros
    printf("%d %d\n", bbstr_global_ref_count, bbstrnode_global_ref_count);

    return 0;
*/
```
While BBStr may need a close look, we can improve the usage guide in the meantime. Delete lists/strings functionality not unlike malloc/calloc/free. Let's specify static memory in engineering document and pass through DCO; code needs to reflect spec, not the other way around (spec reflects code).
This can start with an Excel spreadsheet.
Static memory will force us to optimize some buffer usage across codebase that could be improved.

```
// **************************************************************************************
// TYPEDEFS
// **************************************************************************************

typedef struct _BBStr {
    char *str;
    int ref_count;
} BBStr;

typedef struct _BBStrNode {
    BBStr *bbstr;
    struct _BBStrNode *next;
} BBStrNode;
```
All that in bbstr.c just for ref_count? Let's review.


```

// **************************************************************************************
// THEORY
// (Why is does this module exist?)
// (Why was some simpler option avoided?)
// (What non-obvious vocabulary is used?)
// (What naming conventions are used?)
// **************************************************************************************
```
Let's establish a documentation standard (informal, non qms) that we all use; these templates were rarely filled out but should be somewhere.

```
int cli_split_args(char *command, char **out_args, int max_args) {
    // Split a string by whitespace; eg: "foo bar 123" -> out_args: ["foo", "bar", "123"]
    // Writes up to max_args into out_args and returns number of split args
    bool seaching_for_non_whitespace = false;
    int arg_i = 0;
    char *last_start = command;
    char *curr = last_start;
    char *end = &command[strlen(command)];
    while (curr <= end) {
        bool is_whitespace = (*curr == ' ' || *curr == '\t' || *curr == '\r' || *curr == '\n');
        if (seaching_for_non_whitespace) {
            if (! is_whitespace) {
                last_start = curr;
                seaching_for_non_whitespace = 0;
            }
        }
        else {
            if (is_whitespace || *curr == 0) {
                *curr = 0;
                out_args[arg_i] = last_start;
                arg_i++;
                seaching_for_non_whitespace = 1;
            }
        }
        if (arg_i >= max_args) {
            break;
        }
        curr++;
    }
    return arg_i;
}
```
Redundant, verbatim repeat of string checking logic from BBStr API, breaks abstraction or warrants removal of API. Is this the best way to process arguments? We can set a strict input format to simplify checks.

```
Err cli_parse_gpio_pin_string(char *arg, GPIO_TypeDef **block, uint16_t *pin) {
    // Convert a string like "A5" to the correct GPIO block
    // and pin number. Return 0 on success.
    char blockLetter = arg[0];
    char *blockPin = &arg[1];
    if (blockLetter >= 'a' && blockLetter <= 'g') {
        blockLetter = (blockLetter - 'a') + 'A';
    }

    GPIO_TypeDef *gpioBlocks[] = {GPIOA, GPIOB, GPIOC, GPIOD, GPIOE, GPIOF, GPIOG};

    if (blockLetter >= 'A' && blockLetter <= 'G') {
        *block = gpioBlocks[blockLetter - 'A'];
        *pin = atoi(blockPin);
        return NOERR;
    }

    return -1;
}
```
Improve error specificity, migrate away from entering strings for GPIO and instead input pin number (chip referenced). Eliminates need for 2 translation steps, saves memory, and further reduces potential fallout from BO overwriting LU's for pin assignment.

```
#ifndef CLI_HELPERS_H
#define CLI_HELPERS_H
```
Does this do anything?

## comm
```
uint8_t _xmit_buffer[N_FIFO_PACKETS * PACKET_MEM_SIZE];
uint8_t _recv_buffer[N_FIFO_PACKETS * PACKET_MEM_SIZE];
```
Revise nomeclature.

```
/**
 * @brief Waits after UART IDLE event to allow DMA transfer to complete.
 *
 * Ensures enough delay after an IDLE interrupt for DMA transfer to finish
 * so that frame processing does not occur prematurely, which could lead to
 * CRC errors or packet loss.
 */
void _receive_idle_wait_for_dma() {
    // When the IDLE interrupt fires the DMA is typically not done transferring.

    // I don't think there's a good way of doing this that isn't packet-size aware
    // because the DMA has no idea how many bytes are coming and therefore checking
    // its registers only tells you how far it is from filling the max-size buffer.
    //
    // Furthermore, if I use a size-based in the packet prefix then I might get a corruption
    // and then block for too long (although I can limit the problem by limiting to the max buffer size).
    //
    // If I wanted to so that size check without that failure mode then I'd need to apply a CRC to the
    // header and a different CRC to the data block.
    //
    // For now, I'm going to simply spin and in the case that this proceeds too early
    // it will result in a failed CRC and thus a packet drop.
    // Based on tests:
    //   20 was sufficeint 0% of the time
    //   30 was sufficient 50% of the time
    //   40 was sufficient 100% of the time
    for (int i = 0; i < 40; i++) {
    }
}
```
Perhaps we have DMA module send ready flag/read ready flag from peripheral as separate interrupt instead of timing relative to UART_IDLE -> NOT SAFE!


```
/**
 * @brief Callback for DMA error interrupts.
 *
 * Logs DMA error flags for debugging purposes.
 *
 * @param hdma Pointer to DMA handle where the error occurred.
 */
void HAL_DMA_ErrorCallback(DMA_HandleTypeDef *hdma) {
    printf("HAL_DMA_ErrorCallback\n");
    if (__HAL_DMA_GET_FLAG(hdma, DMA_FLAG_TC6)) {
        printf("  DMA_FLAG_TC6: Transfer complete\n");
    }
    if (__HAL_DMA_GET_FLAG(hdma, DMA_FLAG_HT6)) {
        printf("  DMA_FLAG_HT6: Half-transfer complete\n");
    }
    if (__HAL_DMA_GET_FLAG(hdma, DMA_FLAG_TE6)) {
        printf("  DMA_FLAG_TE6: Trasfer error\n");
    }
    if (__HAL_DMA_GET_FLAG(hdma, DMA_FLAG_GL6)) {
        printf("  DMA_FLAG_GL6: Global interrupt\n");
    }
}
```
Let's review errors across codebase, could we fold this into a general error format? Consistently ad-hoc flags and printouts need to be overhauled into consolidated system.

```
/**
 * @brief Callback for UART error interrupts.
 *
 * Handles UART overrun, framing, noise, and other errors. Attempts recovery by
 * restarting reception or flushing buffers.
 *
 * @param huart Pointer to UART handle where the error occurred.
 */
void HAL_UART_ErrorCallback(UART_HandleTypeDef *huart) {
    printf("HAL_UART_ErrorCallback: ");

    if (huart->ErrorCode & HAL_UART_ERROR_ORE) {
        // TODO: I do not understand under what situation this occurs.
        // Right now its happening whenver the CMS sleeps for a long time.
        HAL_UART_DMAStop(huart);
        __HAL_UART_CLEAR_OREFLAG(huart);
        comm_recv_packets();
    }

    if (huart->ErrorCode & HAL_UART_ERROR_PE) {
        printf("Parity Error\n");
    }
    if (huart->ErrorCode & HAL_UART_ERROR_NE) {
        printf("Noise Error\n");
    }
    if (huart->ErrorCode & HAL_UART_ERROR_FE) {
        printf("Framing Error\n");
        HAL_UART_DMAStop(huart);
        __HAL_UART_CLEAR_FLAG(huart, UART_CLEAR_FEF);
        __HAL_UART_FLUSH_DRREGISTER(huart);
        __HAL_UART_CLEAR_OREFLAG(huart);
        comm_recv_packets();
    }
    if (huart->ErrorCode & HAL_UART_ERROR_ORE) {
        printf("Overrun Error\n");
    }
    if (huart->ErrorCode & HAL_UART_ERROR_DMA) {
        printf("DMA Transfer Error\n");
    }
    if (huart->Instance->ISR & USART_ISR_PE) {
        printf("  USART_ISR_PE\n");
    }
    printf("ISR State: ");
    if (huart->Instance->ISR & USART_ISR_FE) {
        printf("USART_ISR_FE ");
    }
    if (huart->Instance->ISR & USART_ISR_NE) {
        printf("USART_ISR_NE ");
    }
    if (huart->Instance->ISR & USART_ISR_ORE) {
        printf("USART_ISR_ORE ");
    }
    if (huart->Instance->ISR & USART_ISR_IDLE) {
        printf("USART_ISR_IDLE ");
    }
    if (huart->Instance->ISR & USART_ISR_RXNE) {
        printf("USART_ISR_RXNE ");
    }
    if (huart->Instance->ISR & USART_ISR_TC) {
        printf("USART_ISR_TC ");
    }
    if (huart->Instance->ISR & USART_ISR_TXE) {
        printf("USART_ISR_TXE ");
    }
    if (huart->Instance->ISR & USART_ISR_LBDF) {
        printf("USART_ISR_LBDF ");
    }
    if (huart->Instance->ISR & USART_ISR_CTSIF) {
        printf("USART_ISR_CTSIF ");
    }
    if (huart->Instance->ISR & USART_ISR_CTS) {
        printf("USART_ISR_CTS ");
    }
    if (huart->Instance->ISR & USART_ISR_RTOF) {
        printf("USART_ISR_RTOF ");
    }
    if (huart->Instance->ISR & USART_ISR_EOBF) {
        printf("USART_ISR_EOBF ");
    }
    if (huart->Instance->ISR & USART_ISR_ABRE) {
        printf("USART_ISR_ABRE ");
    }
    if (huart->Instance->ISR & USART_ISR_ABRF) {
        printf("USART_ISR_ABRF ");
    }
    if (huart->Instance->ISR & USART_ISR_BUSY) {
        printf("USART_ISR_BUSY ");
    }
    if (huart->Instance->ISR & USART_ISR_CMF) {
        printf("USART_ISR_CMF ");
    }
    if (huart->Instance->ISR & USART_ISR_SBKF) {
        printf("USART_ISR_SBKF ");
    }
    if (huart->Instance->ISR & USART_ISR_RWU) {
        printf("USART_ISR_RWU ");
    }
    if (huart->Instance->ISR & USART_ISR_WUF) {
        printf("USART_ISR_WUF ");
    }
    if (huart->Instance->ISR & USART_ISR_TEACK) {
        printf("USART_ISR_TEACK ");
    }
    if (huart->Instance->ISR & USART_ISR_REACK) {
        printf("USART_ISR_REACK ");
    }
    printf("\n");

    comm_enable_reception();
}
```
Safe but can be folded into LUT for concision.


```
    if (huart->ErrorCode & HAL_UART_ERROR_ORE) {
        // TODO: I do not understand under what situation this occurs.
        // Right now its happening whenver the CMS sleeps for a long time.
        HAL_UART_DMAStop(huart);
        __HAL_UART_CLEAR_OREFLAG(huart);
        comm_recv_packets();
    }
```
This is from the same snippet as above: need to investigate in emulator and understand.



```
/**
 * @brief UART transmission complete callback.
 *
 * Called when DMA transmission is complete. Enables reception and triggers
 * next receive call.
 *
 * @param huart Pointer to UART handle that finished transmitting.
 */
void HAL_UART_TxCpltCallback(UART_HandleTypeDef *huart) {
    // Called by the HAL when a transmission is complete.
    // This is in the context of an interrupt.
    if (huart->ErrorCode != 0 || huart->Instance != USART2) {
        printf("HAL_UART_TxCpltCallback. huart->ErrorCode = %u\n", (unsigned)huart->ErrorCode);
    }
    else {
        comm_enable_reception();
        comm_recv_packets();
        xmit_done_count++;
    }
}
```
Investigate.

```
#if ! defined(CRIT_SECT_TEST) && ! defined(ATOMIC_INC_TEST)
/**
 * @brief Timer interrupt callback for elapsed period.
 *
 * Transmits packets after a delay to simulate reply timing.
 *
 * @param htim Timer handle which triggered the callback.
 */
void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim) {
    // After a bit of delay we can now send the reply.
    if (htim->Instance == TIM2) {
        comm_xmit_packets();
    }
}
#endif
```
Need standard for writing tests.

```
/**
 * @brief UART receive event callback for IDLE detection.
 *
 * Handles frame reception using DMA and verifies CRC. Decodes valid packets into
 * the receive FIFO and optionally schedules a reply using a timer.
 *
 * @param huart UART handle that received data.
 * @param size Number of bytes received.
 */
void HAL_UARTEx_RxEventCallback(UART_HandleTypeDef *huart, uint16_t size) {
    if (huart->ErrorCode != 0 ) {
        // TODO Proper error handling
        printf("HAL_UARTEx_RxEventCallback. huart->ErrorCode = %u\n", (unsigned)huart->ErrorCode);
    }
    if(huart->Instance != USART2) {
        printf("HAL_UARTEx_RxEventCallback non-usart2\n");
    }

    HAL_UART_RxEventTypeTypeDef event = HAL_UARTEx_GetRxEventType(huart);
    if (event == HAL_UART_RXEVENT_IDLE) {
        _receive_idle_wait_for_dma();

        uint16_t bytes_received = sizeof(_recv_buffer) - __HAL_DMA_GET_COUNTER(huart->hdmarx);

        // A frame has arrived. Split it into packets and check the CRC.
        Frame *frame = (Frame *)_recv_buffer;

        // Compare receved and computed CRC
        uint32_t recv_crc = frame->crc;
        frame->crc = 0;
        uint32_t comp_crc = crc32_calc((uint8_t *)frame, bytes_received, CRC_INITIAL);

        Packet *last_dst_packet = NULL;

        if (comp_crc == recv_crc) {
            // Decode the frame into packets into the recv fifo
            int src_i = 0;
            for (int i = 0; i < frame->n_packets; i++) {
                if (src_i < bytes_received) {
                    Packet *src_packet = (Packet *)&frame->packets[src_i];
                    size_t src_size = src_packet->n_bytes;
                    if (src_i + src_size <= bytes_received) {
                        Packet *dst_packet = fifo_writ_get_ptr(&recv_fifo);
                        if (dst_packet) {
                            last_dst_packet = dst_packet;
                            if (src_size <= PACKET_SIZE) {
                                memcpy(dst_packet, src_packet, src_size);

                                // printf("<-------- recv_packet\n  ");
                                // packet_dump(dst_packet);

                            }
                            fifo_writ_done(&recv_fifo);
                        }
                        else {
                            // printf("Overflow. No place to put next recv packet\n");
                        }
                        src_i += src_size;
                    }
                }
            }
        }
        else {
            printf("Error: CRC check failed on received packet\n");
        }

        if (_comm_reply_callback) {
            (*_comm_reply_callback)(last_dst_packet);

            // At 100 was good enough
            // 50 was also good enough
            // 25 was too little -- BUT, and this is weird. It is only too little for the FIRST packet. WHy?
            // There's somethign different about the first time. Somethign about the CMS start isn't fast at first.
            // I really don't see what it is so maybe I should just reduce the timeout period? Or maybe for the first
            // packet?
            const uint32_t reply_delay_ms = 25;
            comm_timer_start(reply_delay_ms);
        }
        else {
            comm_recv_packets();
        }

        recv_done_count++;
    }
    else {
        // This could be a HT or full buffer.
        // In the case of a full buffer it means that somehow something larger than a full packet
        // was sent so this is a serious error that should be handled.
    }
}
```
Not acceptable to leave unfinished code, unhandled errors, and trial&error derived timings in production code. Needs revision asap.

```
void comm_timer_start(uint32_t period_ms) {
    // When the period_ms is less than 2 the timer doesn't work.
    // There's go to be some genral solution to that but I don't relaly
    // care right now while I'm debugging the reply timing so I'm just going to make the minimum 2.
    period_ms = max(2, period_ms);

    TIM_HandleTypeDef *htim = &htim2;

    HAL_TIM_Base_Stop_IT(htim);

    // Set the desired prescaler and auto-reload values to match the required period
    uint32_t clock_freq = HAL_RCC_GetPCLK1Freq(); // Or PCLK2 depending on the timer
    uint32_t prescaler = (clock_freq / 1000) - 1; // Convert clock to milliseconds
    uint32_t period = period_ms - 1;

    // Set the prescaler and the period (ARR) for the timer
    __HAL_TIM_SET_PRESCALER(htim, prescaler);
    __HAL_TIM_SET_AUTORELOAD(htim, period);

    // Start the timer in interrupt mode
    __HAL_TIM_SET_COUNTER(htim, 0);              // Reset the counter
    __HAL_TIM_CLEAR_FLAG(htim, TIM_FLAG_UPDATE); // Clear any pending update event

    __HAL_TIM_ENABLE_IT(htim, TIM_IT_UPDATE); // Enable the update interrupt explicitly

    // Ensure the timer is in OPM mode (One Pulse Mode)
    htim->Instance->CR1 |= TIM_CR1_OPM;
    Err err = HAL_TIM_Base_Start_IT(htim);
    inquis_assert(err == 0);
}
```
Good that it works, we should know why one and done.


```
void comm_xmit_packets() {
    // Copy all of the xmit packets in the FIFO into a single xmit_buffer, compute CRC, frame and start DMA xmit.
    int n_avail = fifo_n_avail(&xmit_fifo);

    Frame *frame = (Frame *)_xmit_buffer;
    frame->crc = 0;
    frame->n_packets = n_avail;
    uint8_t *dst = frame->packets;

    for (int i = 0; i < n_avail; i++) {
        Packet *packet = fifo_read_get_ptr(&xmit_fifo, 0);
        if (packet) {
            // printf("--------> xmit_packet[%d]\n  ", i);
            // packet_dump(packet);

            uint8_t *src = (uint8_t *)packet;
            int src_size = packet->n_bytes;
            memcpy(dst, src, src_size);
            dst += src_size;
            inquis_assert(dst - _xmit_buffer < sizeof(_xmit_buffer));
            fifo_read_done(&xmit_fifo);
        }
    }

    size_t xmit_size = dst - _xmit_buffer;
    frame->crc = crc32_calc((uint8_t *)frame, xmit_size, CRC_INITIAL);

    comm_enable_transmission();
    Err err = HAL_UART_Transmit_DMA(&huart2, _xmit_buffer, xmit_size);
    if (err != HAL_OK) {
        printf("  ERROR: HAL_UART_Transmit_DMA, err = %d\n", err);
    }
}
```
Replace commented out debug lines with ifdef blocks for consistency.

## common

```
// To get this value I have to remove the "static" declaration in
extern uint8_t *__sbrk_heap_end;
```
???

```
#if TESTING_ENABLED == 1
// Used to monitor the error conditions by tests
char *try_scope_error_handler_was_run_msg = NULL;
char *try_scope_error_handler_was_run_file = NULL;
int try_scope_error_handler_was_run_line = 0;
#endif
```
Not the way to do this, let's start here when speccing the new error reporting framework.


```
/**
 * @brief Error handler used by TRY macros for testing and logging.
 *
 * Emits debug messages and optionally tracks error details for testing purposes.
 *
 * @param msg   Description of the failed operation.
 * @param err   Error code returned.
 * @param file  Source file where the error occurred.
 * @param line  Line number where the error occurred.
 */
void try_scope_error_handler(char *msg, Err err, char *file, int line) {
#if TESTING_ENABLED == 1
    if (tests_running) {
        try_scope_error_handler_was_run_msg = msg;
        try_scope_error_handler_was_run_file = file;
        try_scope_error_handler_was_run_line = line;
    }
    else {
        try_scope_error_handler_was_run_msg = NULL;
        try_scope_error_handler_was_run_file = NULL;
        try_scope_error_handler_was_run_line = 0;
    }
#endif
    emit_debug("Try-Catch Error: '%s' failed with code: %d @%s:%d\n", msg, err, file, line);
}
```
Same comment as above and case and point. Needs a close look, this approach is unsustainable in production and for sophisticated stacktraces.



```
/**
 * @brief Sleeps for the specified number of milliseconds while petting the watchdog.
 *
 * @param ms Duration in milliseconds.
 */
void sleep_ms(int ms) {
    // Sleep and pet the watchdog every 100ms
    while (ms > 0) {
        pet_watchdog();
        int _ms = min(ms, 100);
        HAL_Delay(_ms);
        ms -= _ms;
    }
}
```
Funny.


```
/**
 * @brief Returns the current system time in milliseconds since boot.
 */
TimeMS get_time_ms() {
    // This is wrapped to avoid inclusion of the entire HAL headers into the state headers.
    return (TimeMS)HAL_GetTick();
}
```
Investigate further, may have better approach.


```
/**
 * @brief Returns adjusted time with offset applied.
 *
 * Do not use for timers, as time may go backward.
 */
TimeMS get_sync_time_ms() {
    // TODO: This wil have an adjustable offset which might allow time to go backwards
    // so do not use as a timer.
    return get_time_ms() - _time_difference_ms;
}
```
Trace usage with Doxygen; why does this exist given the reverse time bug?


```
/**
 * @brief Halts program execution, continuously pets the watchdog.
 *
 * @param msg Optional message to emit before halting.
 */
void halt(char *msg) {
    // TODO Emit message to BOTH stdout and to SD Card streams
    if (msg) {
        printf("%s", msg);
    }
    fflush(stdout);
    fflush(stderr);

    // #if TESTING_ENABLED == 1
    //     if (inttest_bypass_halt != 0) {
    //         inttest_bypass_halt_reason = msg;
    //         return;
    //     }
    // #endif

    // Loop forever
    while (1) {
        pet_watchdog();
    }
}
```
Unfinished code. Trace usage with Doxygen; why do we explicitly halt as opposed to simply exiting?


```
 /*
    This function is for the "Buffer manipulation paranoia level 10" pattern
    wherein you check the size of a buffer before you write into it
    AND you check it again with a strlen afterwards to ensure you didn't overwrite.

    Args:
        dst: The destination buffer.
            This is used for sanity checking (non-NULL) and also for strlen.
            It is also convenient in the case of a real memory corruption in that
            you could log or check these addresses in debug mode.
        dst_buf_size:
            The total size of the buffer.
        n_chars:
            The number of characters to write. Because of C's nul-string
            character this must be <= dstBufSize - 1
        stop_on_fail:
            If true then it halts execution on failure.

    Returns:
        err-style. 0=success

    Example usage:
        void write_a_string(char *buf, int buf_len, float value) {
            // This will write an 8 character string of value into buf

            int err = 0;
            TRY_START {
                const int need_chars = 8;
                err = stringBufferCheck(buf, buf_len, need_chars, false);
                TRY_CHECK("destination string not long enough for target");

                // Use snprintf, note that a common mistake is to
                // Forget to -1 on the n. This would be caught by
                // the following second check.
                snprintf(buf, bufMaxSize - 1, "%08.1f", value);

                err = stringBufferCheck(buf, buf_len, 0, false);
                TRY_CHECK("destination string overwrote end of buffer");

            } TRY_END;
        }

        void main() {
            #define BUF_LEN (16)
            char dstBuf[BUF_LEN];
            writeAString(char *buf, int buf_len, float value) {
        }
    */
```
Pythonic docstring?


```
// Based on
// https://community.st.com/t5/stm32-mcu-products/how-do-you-measure-the-execution-cpu-cycles-for-a-section-of/td-p/213709
volatile unsigned int *DWT_CYCCNT = (volatile unsigned int *)0xE0001004;
volatile unsigned int *DWT_CONTROL = (volatile unsigned int *)0xE0001000;
volatile unsigned int *DWT_LAR = (volatile unsigned int *)0xE0001FB0;
volatile unsigned int *SCB_DHCSR = (volatile unsigned int *)0xE000EDF0;
volatile unsigned int *SCB_DEMCR = (volatile unsigned int *)0xE000EDFC;
volatile unsigned int *ITM_TER = (volatile unsigned int *)0xE0000E00;
volatile unsigned int *ITM_TCR = (volatile unsigned int *)0xE0000E80;
static int Debug_ITMDebug = 0;

/**
 * @brief Enables CPU cycle counter (DWT_CYCCNT) for profiling.
 */
void enable_timing() {
    if ((*SCB_DHCSR & 1) && (*ITM_TER & 1)) {
        Debug_ITMDebug = 1;
    }

    *SCB_DEMCR |= 0x01000000;
    *DWT_LAR = 0xC5ACCE55; // enable access
    *DWT_CYCCNT = 0;       // reset the counter
    *DWT_CONTROL |= 1;     // enable the counter
}
```
Not needed, this should be profiled in emulation.


```
/**
 * @brief Fails with an assert and halts while petting the watchdog.
 *
 * @param msg Assertion message.
 * @param file Source file name.
 * @param line Line number of failure.
 */
void inquis_assert_failed(char *msg, char *file, int line) {
    // We use a custom version of assert here instead of the
    // standard C assert because we do not want to exit but
    // rather we want to go into a halt() that will pet the watchdog.
    char buf[256];
    sprintf(buf, "Assert failed: '%s' at %s:%d\n", msg, file, line);
    halt(buf);
}
```
Same comments about overhauling error handling; we also need a better naming standard, inquis randomly appears here.


```
/**
 * @brief Prints a hexadecimal and ASCII representation of memory.
 *
 * @param _ptr Pointer to memory.
 * @param n_bytes Number of bytes to dump.
 */
void hex_dump(void *_ptr, uint32_t n_bytes) {
    int i, j;
    int last_line_start_i = 0;
    uint8_t *ptr = (uint8_t *)_ptr;

    for (i = 0; i < n_bytes; i++) {
        pet_watchdog();
        if (i % 16 == 8) {
            printf(" ");
        }
        printf("%02x ", ptr[i]);
        bool is_end = i == n_bytes - 1;
        if ((i > 0 && i % 16 == 15) || is_end) {
            printf("  ");
            if (is_end) {
                int padding = i % 16 == 15 ? 0 : 16 - ((i + 1) % 16);
                for (j = 0; j < padding; j++) {
                    printf("   ");
                }
                if (padding >= 8) {
                    printf(" "); // Center gap.
                }
            }
            int w = i - last_line_start_i + 1; // +1 because we're at %16 == 15
            for (int j = 0; j < w; j++) {
                if (j % 16 == 8) {
                    printf(" ");
                }
                uint8_t c = ptr[last_line_start_i + j];
                printf("%c", (c >= 32 && c <= 126) ? c : '.');
            }
            last_line_start_i = i + 1; // +1 because we're at %16 == 15
            printf("\n");
        }
    }
}
```
Verify.


```
/**
 * @brief Asserts that there is sufficient free stack space.
 */
void stack_check() {
    // The value of __sbrk_heap_end wil be wrong until a single malloc is called
    // extern uint8_t _estack; // Defines the bottom of the stack (which is higher in memory as the stack grows down)
    uint32_t stack_top = __get_MSP();
    // int stack_size = (int)((unsigned)&_estack - (unsigned)stack_top);
    int stack_free_space = (unsigned)stack_top - (unsigned)__sbrk_heap_end;
    // printf("stack_size=%d stack_free=%d\n", stack_size, stack_free_space);
    inquis_assert(stack_free_space > 512);
}
```
Unfinished code and potentially trouble.


```

// A TRY_SCOPE is a C preprocessor macro-set to make a scope-like
// block that acts like a try-finally block.
//   It is particularly useful when there are a long series
// of verbose and repetitive error checks as it allows
// the block of checks to terminate early and jump over
// the code that should not be exxecuted given the error mode.
//
// For example:
//   void try_scope_error_handler(char *msg, Err err, char *file, int line) {
//       printf("Error: '%s' with code: %d @ %s:%d\n", msg, err, file, line);
//   }
//
//   Err err = 0;
//   TRY_START {
//      err = do_something_error_prone();
//      TRY_CHECK("do_something_error_prone");
//      // When err is non-zero we do NOT want to run
//      // do_something_else() NOR get_some_value_that_needs_to_be_in_range()
//
//      err = do_something_else();
//      TRY_CHECK("something_else");
//
//      int someVal = get_some_value_that_needs_to_be_in_range();
//      TRY_CHECK_IS(someVal < 10, "someVal was wrong");
//   }
//   TRY_END;
//
//   printf("This will be run no matter the success or failure.\n");

#define TRY_START do
#define TRY_END                                                                                                        \
    while (0)                                                                                                          \
        ;
#define TRY_CHECK(fail_msg)                                                                                            \
    if (err != 0) {                                                                                                    \
        try_scope_error_handler(fail_msg, err, __FILE__, __LINE__);                                                    \
        break;                                                                                                         \
    }
#define TRY_CHECK_IS(predicate, fail_msg)                                                                              \
    if (! (predicate)) {                                                                                               \
        err = __LINE__;                                                                                                \
        try_scope_error_handler(fail_msg, err, __FILE__, __LINE__);                                                    \
        break;                                                                                                         \
    }

// We use a custom version of assert here instead of the
// standard C assert because we do not want to exit but
// rather we want to go into a halt() that will pet the watchdog.
// There should be NO references to assert() anywhere.
#define inquis_assert(x)                                                                                               \
    if (! (x)) {                                                                                                       \
        inquis_assert_failed(#x, __FILE__, __LINE__);                                                                  \
    }
```
Need better error handling.


Remarks on common: needs extensive work to bring up to spec. Should be one of primary focuses in upcoming code review and project to spec error system.

## config

```

char *_config_names[] = {
    // Do NOT change this without also updating config.h:Config and default_config.txt also.
    "cath_24F_imp_scale_factor_times_100",
    "cath_16F_imp_scale_factor_times_100",

    "syringe_motion_start_delta_time_ms",
    "syringe_motion_start_threshold",
    "syringe_motion_stop_delta_time_ms",
    "syringe_motion_stop_threshold",
    "syringe_vacuum_threshold",

    "valve_strike_ms",
    "valve_strike_pwm",
    "valve_hold_pwm",

    "cms_Ls",
    "cms_Lr",
    "cms_v1",
    "cms_v2",
    "cms_v3",
    "cms_v4",
    "cms_v5",
    "cms_v6",
    "cms_v7",
    "cms_v8",
    "cms_TB1",
    "cms_TB3",
    "cms_TB4",
    "cms_TR",
    "cms_Tlatch",
    "cms_Tstack",
    "cms_Tup",
    "cms_BatLow",
    "cms_Timeout",
    "cms_J",
    "cms_C",
    "cms_M",
    "cms_Trst",
    "cms_Tblue",
    "cms_Toff",
    // "cms_piston_back_alert_ms",
    "handle_impedance_filter_n",
    // "handle_start_aspiration_n_samples_lookback",
    // "handle_aspiration_n_samples",
    "handle_range_2",
    "handle_range_3",
    "handle_range_4",
    "handle_range_5",
    "handle_A",
    "handle_B",
    "handle_D",
    "handle_G",
    "handle_H",
    "handle_K",
    "handle_L",
    "handle_L2",
    "handle_N",
    "handle_P",
    "handle_Pdrop",
    "handle_Pfilter",
    "handle_Q",
    "handle_R",
    "handle_X",
    "handle_Tdrop",
    "handle_W",
    "handle_Lookback",
    
    "handle_disallow_wall_latch",

    "cms_light_off_rgb",
    "cms_light_connecting_rgb",
    "cms_light_cms_error_rgb",
    "cms_light_imp_state_1_short_circuit_rgb",
    "cms_light_imp_state_2_saline_blood_wall_rgb",
    "cms_light_imp_state_3_clot_rgb",
    "cms_light_imp_state_4_air_rgb",
    "cms_light_imp_state_5_open_circuit_rgb",
    "cms_light_fluid_injection_rgb",
    "cms_light_wall_latch_rgb",
    "cms_light_handle_error_rgb",
    "cms_light_clogged_rgb",
    "cms_light_lid_removed_rgb",
    "cms_light_out_of_co2_rgb",

    "han_light_off_rgb",
    "han_light_connecting_rgb",
    "han_light_cms_error_rgb",
    "han_light_imp_state_1_short_circuit_rgb",
    "han_light_imp_state_2_saline_blood_wall_rgb",
    "han_light_imp_state_3_clot_rgb",
    "han_light_imp_state_4_air_rgb",
    "han_light_imp_state_5_open_circuit_rgb",
    "han_light_fluid_injection_rgb",
    "han_light_wall_latch_rgb",
    "han_light_handle_error_rgb",
    "han_light_clogged_rgb",
    "han_light_lid_removed_rgb",
    "han_light_out_of_co2_rgb",

    "test_rig_light_button_pressed",
    "test_rig_light_low_pressure",
    "test_rig_light_disconnected",

    "calib_m_times_1000",
    "calib_b_times_1000",

    "Tcom",
    "Tbeep",
    "TaudioBlank",
    "flash_half_period_in_ms",
    "debug_mode",

    "audio_clot_file_number",
    "audio_warnback_file_number",
    "audio_clot_volume_divisor",
    "audio_warnback_volume_divisor",

    "handle_test_rig",
};
```
This is unsafe; chance of silent failure if edits out of sync with header.


```
// Inspired by https://stackoverflow.com/a/54975587
char *_default_config_file_static_str = (
#include "default_config.txt"
);
```
Investigate, probably better solution.


```
BBStrNode *_strip_comments(BBStrNode *head) {
    // Delete the lines that are comments
    // Returns new head (which might or might not change).
```
Probably not necessary if we parse the right way


```
    int n_config_fields = sizeof(Config) / sizeof(int);
    // This assert is to catch the case during development that
    // a dev forgot to add a name to config_names after adding
    // a field to Config (or vice-versa) and will never happen
    // in release builds.
```
Confirm if true/if built into rest of code; can we trust this assumption.

```
Config *default_config() {
    // used especially for testing
    static Config default_config;
    static bool default_config_cached = false;
    Err err = 0;
    if (! default_config_cached) {
        BBStr *config_file_contents = bbstr_new(_default_config_file_static_str, BBSTR_COPY);
        err = _parse_config_file(config_file_contents, &default_config, true);
        if (err) {
            halt("The default_config.txt did not parse correctly. This is fatal.\n");
        }
        bbstr_del(config_file_contents);
        emit_log_comment_record("Default config loaded successfully\n");
        default_config_cached = true;
    }
    return &default_config;
}
```
If we overhaul the string-name based LUT for config then we can set default values to LUT that remove need for this approach.


```
// void dump_config(char *filename) {
//     BBStr *config_file_contents = sd_card_read_file(filename);
//     if (! config_file_contents) {
//         printf("Unable to load config '%s'\n", filename);
//         return;
//     }
//     printf("%s\n", config_file_contents->str);
//     bbstr_del(config_file_contents);
//     inquis_assert(bbstrnode_global_ref_count == 0);
//     inquis_assert(bbstr_global_ref_count == 0);
// }
```
Let's remove deprecated blocks of code if possible. They still live in repo history.


```
/**
 * @brief Initializes the CRC-32 lookup table.
 *
 * Precomputes a 256-entry table using the standard polynomial (0xEDB88320)
 * to speed up CRC-32 calculation at runtime.
 */
void crc32_init() {
    uint32_t crc;
    for (uint32_t i = 0; i < 256; i++) {
        crc = i;
        for (uint32_t j = 8; j > 0; j--) {
            if (crc & 1) {
                crc = (crc >> 1) ^ POLYNOMIAL;
            }
            else {
                crc >>= 1;
            }
        }
        _crc32_table[i] = crc;
    }
}

/**
 * @brief Computes CRC-32 checksum over a data buffer.
 *
 * Uses a precomputed lookup table for efficient CRC calculation.
 *
 * @param data Pointer to the data buffer to checksum.
 * @param length Number of bytes to process.
 * @param crc Initial CRC value (typically 0xFFFFFFFF).
 * @return The final CRC-32 value after applying the standard final XOR.
 */
uint32_t crc32_calc(uint8_t *data, size_t length, uint32_t crc) {
    while (length--) {
        uint8_t byte = *data++;
        crc = (crc >> 8) ^ _crc32_table[(crc ^ byte) & 0xFF];
    }
    return crc ^ FINAL_XOR_VALUE;
}
```
STM32 may be able to accelerate this.


## defines

```
/* @TODO NOT CLEAN */
#define EMC 0
#define TIP_SIZE 24
```
This should not be a file if it is 2 lines. Can be folded into something else that is already more permanent.

## devices 

```
const int _switch_debounce_ms = 2;
```
Adequate? Stress testing on lid state suggests this needs to be looked at.

```
/**
 * @brief Restarts the microcontroller unit (currently unused and commented out).
 */
void restart_mcu() {
    // HAL_GPIO_WritePin(SHDN_REGS_GPIO_Port, SHDN_REGS_Pin, 1);
    // sleep_ms(1);
    // HAL_GPIO_WritePin(SHDN_REGS_GPIO_Port, SHDN_REGS_Pin, 0);
    // // Lock-up awaiting restart
    // while (1) {
    // }
}
```
Probably good to delete.

```
/**
 * @brief Reads pressure from the Honeywell MPRLS sensor and converts to mmHg.
 *
 * Maintains a simple state machine to request and retrieve sensor data.
 * @param print_debugging If true, prints raw sensor values and error codes.
 * @return Last successfully read pressure value in mmHg.
 */
int read_pressure(bool print_debugging) {
    // Return pressure in mmHg.

    // Note that this function RETURNS THE LAST AVAILABLE pressure
    // which isn't necessarily the current pressure
    // since this call has to maintain a state machine to read the pressure.
    // Asking the chip to begin a reading and then querying that
    // value if the request has been completed.

    // Reference:
    // https://prod-edam.honeywell.com/content/dam/honeywell-edam/sps/siot/en-us/products/sensors/pressure-sensors/board-mount-pressure-sensors/micropressure-mpr-series/documents/sps-siot-mpr-series-datasheet-32332628-ciid-172626.pdf?download=false

    // Read the pressure from the Honeywell MPRLS 30PSI sensor. I2C address 0x18. (Note I2C address are in top 7 bits)
    // 32 bits read: status bytes followed by 24 bit pressure. 0 = LSB
    //     7: always 0
    //     6: power. 1 = device is powered, 0 = not powered
    //     5: busy. 1 = device is busy, 0 = ready
    //     4: always 0
    //     3: always 0
    //     2: memory check status: 0 = memory good, 1 = memory bad
    //     1: always 0
    //     0: math saturation: 1 = saturation error

    // Pressure sampling is done in two steps: request, wait 5ms, read
    // So here we check the time of the last request and only if it has been more
    static int _pressure_last_val = 0;
    static int _pressure_state = 0;
    static TimeMS _pressure_request_time_ms = 0;

    const float pressure_input_min = 0x19999A;
    const float pressure_input_max = 0xE66666;
    const float pressure_output_min = 0;
    const float pressure_output_max = 30;

    #if defined(SUBSYSTEM_HANDLE)
        I2C_HandleTypeDef *hi2c = &hi2c2;
    #elif defined(SUBSYSTEM_CMS)
        I2C_HandleTypeDef *hi2c = &hi2c1;
    #else
        #error("No subsystem defined: must be either CMS or HANDLE")
    #endif

    Err err0, err1 = 0;
    TimeMS now = get_time_ms();

    int elapsed = now - _pressure_request_time_ms;
    uint8_t read_data[4] = {
        0,
    };

    if (_pressure_state == 0 && elapsed > 10) {
        // Pressure request
        uint8_t write_data[] = {0x00, 0x00};
        err0 = HAL_I2C_Mem_Write(hi2c, 0x18 << 1, 0xAA, I2C_MEMADD_SIZE_8BIT, write_data, 2, HAL_MAX_DELAY);
        if (err0 == 0) {
            _pressure_request_time_ms = now;
            _pressure_state = 1;
        }
        else {
            // Try again later
            _pressure_request_time_ms = now;
        }
    }
    else if (_pressure_state == 1) {
        // In experiments it needs less than 6 and it returns an err of zero when it is ready.
        // So we're going to just poll it until we get a good read or we time out.
        err1 = HAL_I2C_Mem_Read(hi2c, 0x18 << 1, 0, I2C_MEMADD_SIZE_8BIT, read_data, sizeof(read_data), HAL_MAX_DELAY);
        if (err1 == 0) {
            // Data is valid, save into _pressure_last_val
            uint32_t press_counts = read_data[3] + read_data[2] * 256 + read_data[1] * 65536;
            
            // A presscount of zero is a special case of failure
            float pressure_psi;
            if(press_counts == 0) {
                pressure_psi = 0;
            }
            else {
                pressure_psi = (
                    ((press_counts - pressure_input_min) * (pressure_output_max - pressure_output_min))
                    / (pressure_input_max - pressure_input_min)
                    + pressure_output_min
                );
            }
            // Convert from PSI to mmHg
            _pressure_last_val = (int)(51.71 * pressure_psi);
            _pressure_request_time_ms = now;
            _pressure_state = 0;
        }
        else {
            // Try again on next call
        }
    }

    if (print_debugging) {
        printf(
            "err0=%d errr1=%d  raw=%02X%02X%02X%02X\n",
            err0,
            err1,
            read_data[0],
            read_data[1],
            read_data[2],
            read_data[3]
        );
    }

    return _pressure_last_val;
}

// For now switch is simple poll-debounce logic.
// Later it might turn out that we need more complex interrupt-based logic if we're
// polling slower than the debounce speed but that logic feels more complex and probably unnecessary.
```
Needs close look, mission critical.


## emc

```

```



##

```

```




---

# Critical

## comm.c
```
/**
 * @brief Callback for UART error interrupts.
 *
 * Handles UART overrun, framing, noise, and other errors. Attempts recovery by
 * restarting reception or flushing buffers.
 *
 * @param huart Pointer to UART handle where the error occurred.
 */
void HAL_UART_ErrorCallback(UART_HandleTypeDef *huart) {
    printf("HAL_UART_ErrorCallback: ");

    if (huart->ErrorCode & HAL_UART_ERROR_ORE) {
        // TODO: I do not understand under what situation this occurs.
        // Right now its happening whenver the CMS sleeps for a long time.
        HAL_UART_DMAStop(huart);
        __HAL_UART_CLEAR_OREFLAG(huart);
        comm_recv_packets();
    }
```

## SD CARD
### sd_card_read_file_binary
```
char *sd_card_read_file_binary(char *filename, size_t *out_size) {
    // Returns a malloc'd buffer. Be sure to free it!
    // I found that opening large files (such as the audio files)
    // was taking enough time that I was resetting the MCU so I added
    // aggressive watchdog petting.
```

### sd_card_get_freespace
```
Err sd_card_get_freespace(uint32_t *out_totalSpace, uint32_t *out_freeSpace) {
    Err err = 0;
    DWORD free_clusters;

    TRY_START {
        // The read free is taking about 2 minutes in some cases
        // as it scans all the sectors. I suspect this is a failure
        // of the card format.
```

## lights.c
```
/* TODO: THE BELOW STATIC DEFINITIONS VIOLATE ABSTRACTION BARRIER, UNSAFE */
static LightVal _curr_light_val = LIGHT_OFF; // TODO wrap into state, avoid explicit peripheral manipulation outside state -> major debug hole potential
static bool _curr_light_on = true; // TODO large name overlap, needs to change, and prev remark about direct manipulation outside state.
static uint32_t _light_val_to_rgb_lut[LIGHT_N_VALS] = { 0, }; // static variable, initialization is redundant
bool _is_flashing = false; // TODO NOT DECLARED STATIC BUT IN STATIC SECTION ||| same suggestion, should not be manipulated globally, or document intent to initialize to defaults in this block
```

## led_driver.c
```
// At 32MHz, a period is 1.0 / 32,000,000 = 3.12e-8 which is 31 nano secs. But they want 200usec == 200,000 nsec.
    // So we need to wait like 6451 clocks before doing anything.

    uint8_t val = 0x7;
    HAL_I2C_Mem_Write(&hi2c3, FRONT_LED_I2C, ENABLE_REGISTER, I2C_MEMADD_SIZE_8BIT, &val, 1, HAL_MAX_DELAY);

    // TODO: Feels like an err here is a legit POST failure that needs to propagate up.
    // inquis_assert(err == 0);

    HAL_I2C_Mem_Write(&hi2c3, REAR_LED_I2C, ENABLE_REGISTER, I2C_MEMADD_SIZE_8BIT, &val, 1, HAL_MAX_DELAY);
```

# Non-Critical, High Importance

## comm.c
```
/**
 * @brief UART receive event callback for IDLE detection.
 *
 * Handles frame reception using DMA and verifies CRC. Decodes valid packets into
 * the receive FIFO and optionally schedules a reply using a timer.
 *
 * @param huart UART handle that received data.
 * @param size Number of bytes received.
 */
void HAL_UARTEx_RxEventCallback(UART_HandleTypeDef *huart, uint16_t size) {
    if (huart->ErrorCode != 0 ) {
        // TODO Proper error handling
        printf("HAL_UARTEx_RxEventCallback. huart->ErrorCode = %u\n", (unsigned)huart->ErrorCode);
    }
    if(huart->Instance != USART2) {
        printf("HAL_UARTEx_RxEventCallback non-usart2\n");
    }

    HAL_UART_RxEventTypeTypeDef event = HAL_UARTEx_GetRxEventType(huart);
    if (event == HAL_UART_RXEVENT_IDLE) {
        _receive_idle_wait_for_dma();
```

## comm.h
```
#include "common.h"
#include "fifo.h"
#include "packet.h"

// **************************************************************************************
// MACROS AND DEFINES
// **************************************************************************************

#define PRSMAGPHA_SAMPLES_PER_PACKET (32) // TODO: Tune
```

## common.c
```
/**
 * @brief Returns adjusted time with offset applied.
 *
 * Do not use for timers, as time may go backward.
 */
TimeMS get_sync_time_ms() {
    // TODO: This wil have an adjustable offset which might allow time to go backwards
    // so do not use as a timer.
    return get_time_ms() - _time_difference_ms;
}

/**
 * @brief Halts program execution, continuously pets the watchdog.
 *
 * @param msg Optional message to emit before halting.
 */
void halt(char *msg) {
    // TODO Emit message to BOTH stdout and to SD Card streams
    if (msg) {
        printf("%s", msg);
    }
    fflush(stdout);
    fflush(stderr);

    // #if TESTING_ENABLED == 1
    //     if (inttest_bypass_halt != 0) {
    //         inttest_bypass_halt_reason = msg;
    //         return;
    //     }
    // #endif

    // Loop forever
    while (1) {
        pet_watchdog();
    }
}
```

## default_config.txt
```
R"#(#
# The first line must be EXACTLY as it appears above TODO NOT CLEAN
```

## defines.h
```
// Modified by inquis_gen_3_0/build.sh
/* @TODO NOT CLEAN */
#define EMC 0
#define TIP_SIZE 24

```

## fifo.h
```
/**
 * @brief Circular buffer for packet exchange between microcontrollers.
 *
 * Manages a fixed-size FIFO queue of raw packet memory blocks, supporting
 * concurrent read/write indices with basic locking. Used for CMS/handle communication.
 */
typedef struct _FIFO {
    uint32_t read_lock;
    uint32_t writ_lock;
    uint32_t read_i;
    uint32_t writ_i;
    uint32_t n_reads; // TODO. Consider if this can roll (and force it in a test)
    uint32_t n_writs;
    uint8_t packets[N_FIFO_PACKETS][PACKET_MEM_SIZE];
} FIFO;
```

## log.c
```
/**
 * @brief Emit an error log message only once.
 *
 * Avoids repeated logging of identical static messages. Tracks unique
 * pointer values to detect duplicates.
 *
 * @param msg Pointer to a static error message string.
 */
void emit_log_error_once(char *msg) {
    // Log msg as an error but only once in case it repeats
    // Assumes that msg is a static string pointer
    // TODO: Add an integration test on this.
    #define N_MSG_PTRS_SEEN_MAX (8)
    static int n_msg_ptrs_seen = 0;
    static char *msg_ptrs_seen[N_MSG_PTRS_SEEN_MAX] = {0,};
```

## lights.c
```
**
 * @brief Load light RGB values from system configuration.
 *
 * Populates the internal lookup table with RGB values for each LightVal
 * enum based on the current system's configuration (CMS or HANDLE).
 *
 * @param config Pointer to the configuration struct with RGB values.
 */
void lights_load_rgb_vals_from_config(Config *config) {

    #if defined(SUBSYSTEM_CMS) /* TODO should be implemented as compiler flag instead of IFDEF, harder to track and debug with IFDEF */
        _light_val_to_rgb_lut[LIGHT_OFF] = config->cms_light_off_rgb;
        _light_val_to_rgb_lut[LIGHT_CONNECTING] = config->cms_light_connecting_rgb;
        _light_val_to_rgb_lut[LIGHT_CMS_ERROR] = config->cms_light_cms_error_rgb;
        _light_val_to_rgb_lut[LIGHT_IMP_STATE_1_SHORT_CIRCUIT] = config->cms_light_imp_state_1_short_circuit_rgb;
        _light_val_to_rgb_lut[LIGHT_IMP_STATE_2_SALINE_BLOOD] = config->cms_light_imp_state_2_saline_blood_wall_rgb;
        _light_val_to_rgb_lut[LIGHT_IMP_STATE_3_CLOT] = config->cms_light_imp_state_3_clot_rgb;
        _light_val_to_rgb_lut[LIGHT_IMP_STATE_4_AIR] = config->cms_light_imp_state_4_air_rgb;
        _light_val_to_rgb_lut[LIGHT_IMP_STATE_5_OPEN_CIRCUIT] = config->cms_light_imp_state_5_open_circuit_rgb;
        _light_val_to_rgb_lut[LIGHT_FLUID_INJECTION] = config->cms_light_fluid_injection_rgb;
        _light_val_to_rgb_lut[LIGHT_WALL_LATCH] = config->cms_light_wall_latch_rgb;
        _light_val_to_rgb_lut[LIGHT_HANDLE_ERROR] = config->cms_light_handle_error_rgb;
        _light_val_to_rgb_lut[LIGHT_CLOGGED] = config->cms_light_clogged_rgb;
        _light_val_to_rgb_lut[LIGHT_LID_REMOVED] = config->cms_light_lid_removed_rgb;
        _light_val_to_rgb_lut[LIGHT_OUT_OF_CO2] = config->cms_light_out_of_co2_rgb;
    #elif defined(SUBSYSTEM_HANDLE) /* ALL OF THIS LOGIC SHOULD BE LOADED FROM HEADER, NOT IN SOURCE */
```

```
#else
    #error("No subsystem defined: must be either CMS or HANDLE") /* TODO: THIS ERROR SHOULD BE THROWN AT COMPILETIME/ENTRY, NOT IN SOURCE!! DANGEROUS IF CAPABLE OF COMPILING WITHOUT DEFINITION OF SUBSYSTEM */
#endif
```

# Nice to Have

## bbstr.c
```
/**
 * @brief Create a new BBStr string object.
 *
 * Allocates a new BBStr structure with a copy of the given string (if provided)
 * or an empty buffer of the specified length.
 *
 * @param s Source string to copy from, or NULL to create an empty string.
 * @param len Length of the string to copy; use -1 to auto-calculate from s.
 * @return Pointer to the newly created BBStr.
 */
BBStr *bbstr_new(char *s, int len) {
    // Create a new bbstr from an existing string or allocate empty.
    // If len < 0 (BBSTR_COPY) then it will use strlen.
    // Len should NOT include the nul.
    // s can be NULL in which case the new buffer is allocated.
    // and filled with zeros.

    // TODO: Remove?
    stack_check();

    if (len < 0) {
```

## config.h
```
/**
 * @struct Config
 * @brief Holds all configurable parameters for CMS and handle behavior.
 *
 * These values are loaded from a configuration file and define system behavior,
 * thresholds, timing, LED colors, calibration values, and test rig settings.
 * All fields must be integers. Modifications require changes in config.c:_config_names
 * and default_config.txt.
 */
typedef struct {
    // DO NOT change this without updating config.c:_config_names!
    // and default_config.txt also.

    // This MUST be all ints! See _set_field_key_val() @TODO NOT CLEAN, USE INTERFACE TO ASSERT TYPES

    int cath_24F_imp_scale_factor_times_100;
    int cath_16F_imp_scale_factor_times_100;

    // CMS config
    int syringe_motion_start_delta_time_ms;
    int syringe_motion_start_threshold;
    int syringe_motion_stop_delta_time_ms;
    int syringe_motion_stop_threshold;
    int syringe_vacuum_threshold;

    int valve_strike_ms;
    int valve_strike_pwm;
    int valve_hold_pwm;

    int cms_Ls;
```

## lights.c
```
// ************************************************************************************** TODO
// THEORY
// (Why is does this module exist?)
// (Why was some simpler option avoided?)
// (What non-obvious vocabulary is used?)
// (What naming conventions are used?)
// **************************************************************************************

// ************************************************************************************** TODO
// INCLUDES
// (Use double quotes, not <>)
// (List system includes first in alphabetic order when possible)
// (Note when order is important)
// **************************************************************************************

#include "stdio.h"

#include "lights.h"
#include "led_driver.h"

// ************************************************************************************** TODO REMOVE
// EXTERN VARIABLES
// (Used rarely, usually imported via #include)
// **************************************************************************************

// ************************************************************************************** TODO REMOVE
// PRIVATE MACROS AND DEFINES
// (Used rarely, usually destined for header files)
// **************************************************************************************

// ************************************************************************************** TODO REMOVE
// PRIVATE TYPEDEFS
// (Used rarely, usually destined for header files)
// **************************************************************************************

// ************************************************************************************** TODO REMOVE
// STATIC VARIABLES
// (Do start each with underscore)
// **************************************************************************************
```

## test_define
```
// This file should be included by any file that refers to TESTING_ENABLED
// It should be included before any other non-stdlib includes
/* @TODO NOT CLEAN */
#define TESTING_ENABLED 1
```

## sample_err.h
```
// **************************************************************************************
// MACROS AND DEFINES
// **************************************************************************************

// @TODO: These need to be cleaned up, not all are applicable anymore

#define SAMPLE_ERR_NONE (0)
#define SAMPLE_ERR_WAKEUP_FAILED (1)          // 5940 did not wake up
#define SAMPLE_ERR_PASSWORD (2)               // FIFO found the password in the stream
#define SAMPLE_ERR_OVERFLOW (3)               // FIFO overflowed
```

## led_driver.c
```
// The intensities appear to be from 0 - 0xb7
    r = (int)r * (int)0xb7 / (int)0xff;
    g = (int)g * (int)0xb7 / (int)0xff;
    b = (int)b * (int)0xb7 / (int)0xff;

    // TODO: Skip these I2C writes if we're not changing and periodically refresh?
    if(_is_on[led_i] && r == 0 && g == 0 && b == 0) {
        _is_on[led_i] = false;
        _rgb_led_set_enable(led_i, false);
    }
    else if (! _is_on[led_i] && (r != 0 || g != 0 || b != 0)) {
        _is_on[led_i] = true;
        _rgb_led_set_enable(led_i, true);
    }
```

## fmt.c
```
// TEMP REMOVED until the state machines are sorted out between handle and cms

// @TODO NOT CLEAN 
```




# Code Tasks Meetig 26/7/2025

- POST doesn't really check anything, just if function returns
- - We call something called post
- - We don't check for all zeros on pressure readings in POST, performed somewhere else
- CLI side, implement raw dump all sensors instead of ?pretty print?
- 

we need to pund on gen 3 , use the shit out of it, and verify that it behaves the way we intended the design

Do everything we can to crash it

Document tests

what's been missing recently is 'someone poundin on the system'

Use flow diagrams to break it

Check for memory leaks

Currently notebooks used and synced out of sharepoint, needs to be concsolidated to git

V4 V5 Vxx logs have different state names associated with them; we need to have a solid method to load in any logs and decode them using the appropriate state names for the version

- Let's put notebooks on colab so people can make a copy of the base to plot their data

- Help steve with monarch board testing system ready/arduino code

