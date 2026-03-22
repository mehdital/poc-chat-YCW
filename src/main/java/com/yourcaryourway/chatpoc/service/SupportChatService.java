package com.yourcaryourway.chatpoc.service;

import com.yourcaryourway.chatpoc.dto.JoinConversationCommand;
import com.yourcaryourway.chatpoc.dto.SendChatMessageCommand;
import com.yourcaryourway.chatpoc.model.AuthorRole;
import com.yourcaryourway.chatpoc.model.SupportMessage;
import com.yourcaryourway.chatpoc.model.SupportMessageType;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

@Service
public class SupportChatService {

    private final ConcurrentMap<String, List<SupportMessage>> messagesByConversation = new ConcurrentHashMap<>();

    public String createConversation() {
        String conversationId = UUID.randomUUID().toString();
        messagesByConversation.putIfAbsent(conversationId, new ArrayList<>());
        return conversationId;
    }

    public SupportMessage registerJoin(JoinConversationCommand command) {
        String content = command.authorName() + " a rejoint la conversation.";
        return appendMessage(
                command.conversationId(),
                SupportMessageType.JOIN,
                AuthorRole.SYSTEM,
                "System",
                content
        );
    }

    public SupportMessage registerLeave(String conversationId, String authorName) {
        return appendMessage(
                conversationId,
                SupportMessageType.LEAVE,
                AuthorRole.SYSTEM,
                "System",
                authorName + " a quitté la conversation."
        );
    }

    public SupportMessage registerChatMessage(SendChatMessageCommand command) {
        return appendMessage(
                command.conversationId(),
                SupportMessageType.CHAT,
                command.authorRole(),
                command.authorName(),
                command.content().trim()
        );
    }

    public List<SupportMessage> getMessages(String conversationId) {
        return List.copyOf(messagesByConversation.computeIfAbsent(conversationId, ignored -> new ArrayList<>()));
    }

    private SupportMessage appendMessage(String conversationId,
                                         SupportMessageType type,
                                         AuthorRole authorRole,
                                         String authorName,
                                         String content) {
        messagesByConversation.putIfAbsent(conversationId, new ArrayList<>());

        SupportMessage message = new SupportMessage(
                UUID.randomUUID(),
                conversationId,
                type,
                authorRole,
                authorName,
                content,
                Instant.now()
        );

        List<SupportMessage> conversation = messagesByConversation.get(conversationId);
        synchronized (conversation) {
            conversation.add(message);
        }

        return message;
    }
}
