import java.util.Random;
import java.util.Scanner;

public class SnakeGame {
    private static final int BOARD_SIZE = 10;
    private static final char SNAKE_CHAR = '*';
    private static final char FOOD_CHAR = '@';

    private int[][] board;
    private int snakeX;
    private int snakeY;
    private int foodX;
    private int foodY;
    private boolean gameOver;

    public SnakeGame() {
        initializeBoard();
        generateFoodPosition();
        gameOver = false;
    }

    private void initializeBoard() {
        board = new int[BOARD_SIZE][BOARD_SIZE];
        for (int i = 0; i < BOARD_SIZE; i++) {
            for (int j = 0; j < BOARD_SIZE; j++) {
                board[i][j] = 0;
            }
        }
    }

    private void generateFoodPosition() {
        Random random = new Random();
        int newFoodX = random.nextInt(BOARD_SIZE - 2) + 1;
        int newFoodY = random.nextInt(BOARD_SIZE - 2) + 1;

        while (isSnakeOnTopOfFood(newFoodX, newFoodY)) {
            generateFoodPosition();
        }

        foodX = newFoodX;
        foodY = newFoodY;
    }

    private boolean isSnakeOnTopOfFood(int foodX, int foodY) {
        return snakeX == foodX && snakeY == foodY;
    }

    public void startGame() {
        Scanner scanner = new Scanner(System.in);

        while (!gameOver) {
            drawBoard(scanner);
            moveSnake(scanner);
            checkCollisions(scanner);
            checkGameOver(scanner);
        }

        scanner.close();
    }

    private void drawBoard(Scanner scanner) {
        for (int i = 0; i < BOARD_SIZE; i++) {
            for (int j = 0; j < BOARD_SIZE; j++) {
                if (board[i][j] == 1) {
                    System.out.print(SNAKE_CHAR);
                } else if (board[i][j] == 2) {
                    System.out.print(FOOD_CHAR);
                } else {
                    System.out.print(" ");
                }
            }
            System.out.println();
        }
    }

    private void moveSnake(Scanner scanner) {
        System.out.print("Enter the direction (up, down, left, right): ");
        String direction = scanner.nextLine();

        switch (direction) {
            case "up":
                if (snakeY > 1 && board[snakeY - 2][snakeX] == 0) {
                    snakeY--;
                } else {
                    System.out.println("Game over! You hit the wall.");
                    gameOver = true;
                }
                break;
            case "down":
                if (snakeY < BOARD_SIZE - 2 && board[snakeY + 2][snakeX] == 0) {
                    snakeY++;
                } else {
                    System.out.println("Game over! You hit the wall.");
                    gameOver = true;
                }
                break;
            case "left":
                if (snakeX > 1 && board[snakeY][snakeX - 2] == 0) {
                    snakeX--;
                } else {
                    System.out.println("Game over! You hit the wall.");
                    gameOver = true;
                }
                break;
            case "right":
                if (snakeX < BOARD_SIZE - 2 && board[snakeY][snakeX + 2] == 0) {
                    snakeX++;
                } else {
                    System.out.println("Game over! You hit the wall.");
                    gameOver = true;
                }
                break;
            default:
                System.out.println("Invalid direction. Use w/a for left, s/d for right, and u/x for up or d/y for down.");
        }
    }

    private void checkCollisions(Scanner scanner) {
        if (snakeX == foodX && snakeY == foodY) {
            System.out.println("You ate the food! The snake grows.");
            initializeBoard();
            generateFoodPosition();
        } else {
            gameOver = true;
            System.out.println("Game over! You hit the wall or the snake.");
        }
    }

    public static void main(String[] args) {
        SnakeGame game = new SnakeGame();
        game.startGame();
    }
}