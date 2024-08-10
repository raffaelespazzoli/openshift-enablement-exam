import pygame  
import sys  
from pygame.locals import *  

# Initialize Pygame  
pygame.init()  

# Set up display properties  
width, height = 800, 600  
screen = pygame.display.set_mode((width, height))  
pygame.display.set_caption("Snake Game")  

# Set up clock and event loop  
clock = pygame.time.Clock()  
while True:  
    # Event handling  
    for event in pygame.event.get():  
        if event.type == QUIT:  
            pygame.quit()  
            sys.exit()  

    # Background color  
    screen.fill((255, 255, 255))  

    # Snake initial position  
    snake_pos = (100, 100)  

    # Draw snake  
    pygame.draw.rect(screen, (0, 0, 0), snake_rect, (25, 25, 50))  

    # Keyboard input  
    for key in pygame.key.get_pressed():  
        if key == K_LEFT:  
            snake_pos[0] -= 1  
        elif key == K_RIGHT:  
            snake_pos[0] += 1  
        elif key == K_UP:  
            snake_pos[1] -= 1  
        elif key == K_DOWN:  
            snake_pos[1] += 1  
        elif key == K_SPACE:  
            if snake_pos[0] == 0 and snake_pos[1] == 0:  
                # The snake has eaten food  
                food_x = random.randint(0, width - 10)  
                food_y = random.randint(0, height - 10)  
                snake_rect = (food_x, food_y, 20, 20)  
                pygame.draw.circle(screen, (0, 0, 0), (food_x, food_y), 5)  

            # Move the snake  
            snake_rect = (snake_pos[0], snake_pos[1])  

    # Check for collision with walls and food  
    collide_left = snake_pos[0] < 0 or snake_pos[0] >= width - 20  
    collide_right = snake_pos[0] + snake_rect.width > width - 10  
    collide_top = snake_pos[1] < 0 or snake_pos[1] >= height - 20  
    collide_bottom = snake_pos[1] + snake_rect.height > height - 10  

    if collide_left:  
        snake_pos[0] = (width - snake_rect.width) // 2  
    elif collide_right:  
        snake_pos[0] = 0  
    elif collide_top:  
        snake_pos[1] = (height - snake_rect.height) // 2  
    elif collide_bottom:  
        snake_pos[1] = height - snake_rect.height  

    # Update snake's position and display  
    clock.tick(60)  

# Quit the game  
pygame.quit()  
sys.exit()