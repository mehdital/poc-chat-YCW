package com.yourcaryourway.chatpoc.model;

import java.time.Instant;
import java.util.UUID;

public class SupportMessage {

    private UUID id;
    private String conversationId;
    private SupportMessageType type;
    private AuthorRole authorRole;
    private String authorName;
    private String content;
    private Instant createdAt;

    public SupportMessage() {
    }

    public SupportMessage(UUID id,
                          String conversationId,
                          SupportMessageType type,
                          AuthorRole authorRole,
                          String authorName,
                          String content,
                          Instant createdAt) {
        this.id = id;
        this.conversationId = conversationId;
        this.type = type;
        this.authorRole = authorRole;
        this.authorName = authorName;
        this.content = content;
        this.createdAt = createdAt;
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public String getConversationId() {
        return conversationId;
    }

    public void setConversationId(String conversationId) {
        this.conversationId = conversationId;
    }

    public SupportMessageType getType() {
        return type;
    }

    public void setType(SupportMessageType type) {
        this.type = type;
    }

    public AuthorRole getAuthorRole() {
        return authorRole;
    }

    public void setAuthorRole(AuthorRole authorRole) {
        this.authorRole = authorRole;
    }

    public String getAuthorName() {
        return authorName;
    }

    public void setAuthorName(String authorName) {
        this.authorName = authorName;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }
}
