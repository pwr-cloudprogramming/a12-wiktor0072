package com.javamaster.controller;

import com.javamaster.controller.dto.ConnectRequest;
import com.javamaster.exception.InvalidGameException;
import com.javamaster.exception.InvalidParamException;
import com.javamaster.exception.NotFoundException;
import com.javamaster.model.FinishedGame;
import com.javamaster.model.Game;
import com.javamaster.model.GamePlay;
import com.javamaster.model.Player;
import com.javamaster.service.GameService;
import com.javamaster.service.S3BucketService;
import lombok.AllArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

@CrossOrigin("*")
@RestController
@Slf4j
@AllArgsConstructor
@RequestMapping("/game")
@ComponentScan(basePackages = {"com.javamaster.service"})
public class GameController {

    private final GameService gameService;
    private final SimpMessagingTemplate simpMessagingTemplate;
    private final S3BucketService bucketService;
    private static final Logger logger = LoggerFactory.getLogger(GameController.class);



    @CrossOrigin("*")
    @PostMapping("/start")
    public ResponseEntity<Game> start(@RequestBody Player player) {
        log.info("start game request: {}", player);
        return ResponseEntity.ok(gameService.createGame(player));
    }

    @PostMapping("/connect")
    public ResponseEntity<Game> connect(@RequestBody ConnectRequest request) throws InvalidParamException, InvalidGameException {
        log.info("connect request: {}", request);
        return ResponseEntity.ok(gameService.connectToGame(request.getPlayer(), request.getGameId()));
    }

    @PostMapping("/connect/random")
    public ResponseEntity<Game> connectRandom(@RequestBody Player player) throws NotFoundException {
        log.info("connect random {}", player);
        return ResponseEntity.ok(gameService.connectToRandomGame(player));
    }

    @PostMapping("/gameplay")
    public ResponseEntity<Game> gamePlay(@RequestBody GamePlay request) throws NotFoundException, InvalidGameException {
        log.info("gameplay: {}", request);
        Game game = gameService.gamePlay(request);
        simpMessagingTemplate.convertAndSend("/topic/game-progress/" + game.getGameId(), game);
        return ResponseEntity.ok(game);
    }

//    @PostMapping("gameplay/reset")
//    public ResponseEntity<Game> reset(@RequestBody GamePlay request) throws NotFoundException, InvalidGameException {
//        log.info("gameplay: {}", request);
//        Game game = gameService.resetGame(request);
//        simpMessagingTemplate.convertAndSend("/topic/game-progress/" + game.getGameId(), game);
//        return ResponseEntity.ok(game);
//    }

    @GetMapping("/results")
    public List<FinishedGame> getAllGames() {
        return gameService.getAllGames();
    }

    @PostMapping("/upload")
    public ResponseEntity<String> handleFileUpload(@RequestParam("file") MultipartFile file, @RequestParam("login") String login) {
        login = login.replace("@", "");
        try {

            if (!bucketService.doesBucketExist("costamguwienko")) {
                bucketService.createBucket( login);
            }
            bucketService.uploadFile("avatar", file, login);
            return ResponseEntity.ok("Plik został pomyślnie przesłany i przetworzony.");
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Wystąpił błąd podczas przetwarzania pliku.");
        }
    }

    @GetMapping("/avatar")
    public ResponseEntity<Resource> getAvatar(@RequestParam("login") String login) throws IOException {
        logger.info("Login: " + login);
        login = login.replace("@", "");
        Resource avatar = bucketService.getFile(login, "avatar");
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_TYPE, MediaType.IMAGE_PNG_VALUE)
                .body(avatar);
    }
}
