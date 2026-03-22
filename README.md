# Your Car Your Way — PoC Chat Support (Java)

## Objectif
Cette preuve de concept valide la faisabilité d'un chat de support client en temps réel, en cohérence avec l'architecture cible retenue pour le projet :

- Java 21
- Spring Boot 3
- WebSocket STOMP
- API REST versionnée
- stockage PostgreSQL prévu dans l'architecture cible

## Ce que couvre le PoC
- création d'une conversation de support ;
- récupération de l'historique d'une conversation ;
- échange temps réel via WebSocket STOMP ;
- interface HTML minimale pour la démonstration.

## Ce que le PoC ne couvre pas
- authentification JWT ;
- persistance PostgreSQL ;
- intégration réelle avec un prestataire de chat / visio ;
- observabilité, audit et sécurité de production.

## Endpoints
- `POST /api/v1/support/conversations`
- `GET /api/v1/support/conversations/{conversationId}/messages`
- `GET /api/v1/support/conversations/health`
- STOMP SockJS : `/ws/support`
- publication :
  - `/app/support.join`
  - `/app/support.send`
- souscription :
  - `/topic/support/{conversationId}`

## Lancement
```bash
mvn spring-boot:run
```

Puis ouvrir :
- `http://localhost:8080/index.html`
