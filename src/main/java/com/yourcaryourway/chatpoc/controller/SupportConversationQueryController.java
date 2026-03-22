package com.yourcaryourway.chatpoc.controller;

import com.yourcaryourway.chatpoc.dto.CreateConversationResponse;
import com.yourcaryourway.chatpoc.model.SupportMessage;
import com.yourcaryourway.chatpoc.service.SupportChatService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/support/conversations")
public class SupportConversationQueryController {

    private final SupportChatService supportChatService;

    public SupportConversationQueryController(SupportChatService supportChatService) {
        this.supportChatService = supportChatService;
    }

    @PostMapping
    public CreateConversationResponse createConversation() {
        return new CreateConversationResponse(supportChatService.createConversation());
    }

    @GetMapping("/{conversationId}/messages")
    public List<SupportMessage> getMessages(@PathVariable String conversationId) {
        return supportChatService.getMessages(conversationId);
    }

    @GetMapping("/health")
    public String health() {
        return "ok";
    }
}
