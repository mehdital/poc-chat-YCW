package com.yourcaryourway.chatpoc.controller;

import com.yourcaryourway.chatpoc.dto.JoinConversationCommand;
import com.yourcaryourway.chatpoc.dto.SendChatMessageCommand;
import com.yourcaryourway.chatpoc.model.SupportMessage;
import com.yourcaryourway.chatpoc.service.SupportChatService;
import jakarta.validation.Valid;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

@Controller
public class SupportChatController {

    private final SupportChatService supportChatService;
    private final SimpMessagingTemplate messagingTemplate;

    public SupportChatController(SupportChatService supportChatService,
                                 SimpMessagingTemplate messagingTemplate) {
        this.supportChatService = supportChatService;
        this.messagingTemplate = messagingTemplate;
    }

    @MessageMapping("/support.join")
    public void join(@Valid JoinConversationCommand command) {
        SupportMessage event = supportChatService.registerJoin(command);
        messagingTemplate.convertAndSend(topic(command.conversationId()), event);
    }

    @MessageMapping("/support.send")
    public void send(@Valid SendChatMessageCommand command) {
        SupportMessage message = supportChatService.registerChatMessage(command);
        messagingTemplate.convertAndSend(topic(command.conversationId()), message);
    }

    private String topic(String conversationId) {
        return "/topic/support/" + conversationId;
    }
}
