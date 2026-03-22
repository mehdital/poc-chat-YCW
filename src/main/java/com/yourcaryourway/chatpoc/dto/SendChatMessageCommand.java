package com.yourcaryourway.chatpoc.dto;

import com.yourcaryourway.chatpoc.model.AuthorRole;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record SendChatMessageCommand(
        @NotBlank String conversationId,
        @NotNull AuthorRole authorRole,
        @NotBlank String authorName,
        @NotBlank String content
) {
}
