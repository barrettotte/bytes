# quick and dirty prototype of projectile motion

import pygame, math, time

pygame.init()
(width, height) = (1200, 800)
screen = pygame.display.set_mode((width, height))
screen.fill((64, 64, 64))
clock = pygame.time.Clock()

pos_scale = 0.1      # scale position down so it fits on small screen
height_error = 0.01  # tolerable error for max height of projectile
g = 9.8              # gravity
theta = 45           # projectile angle

# initial values
v_0 = 250                                  # initial velocity (magnitude)
vx_0 = v_0 * math.cos(theta)               # initial velocity x component
vy_0 = v_0 * math.sin(theta)               # initial velocity y component
(x_0, y_0) = (width * 0.25, height * 0.5)  # initial positions

# estimations
flight_time = (2*vy_0) / g
max_height = ((vy_0**2) / (2*g)) * pos_scale

(x_pos, y_pos, t) = (0,0,0)

while True:
  for event in pygame.event.get():
    if event.type == pygame.QUIT:
      pygame.quit()
      exit()
  if y_pos <= y_0:
    color = (255,0,0) if y_pos < (max_height * (1 + height_error)) else (0,255,0)
    pygame.draw.circle(screen, color, (int(x_pos), int(y_pos)), 2)

    x_pos = x_0 + ((vx_0 * t * math.cos(theta)) * pos_scale)
    y_pos = y_0 - ((vy_0 * t * math.sin(theta) - (0.5 * g * (t**2))) * pos_scale)
    print('t = {}, pos = ({:2f}, {:2f})'.format(t, x_pos, y_pos))

    pygame.display.update()
    clock.tick(60)
    time.sleep(0.1)
    t += 0.50

