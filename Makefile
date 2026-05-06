.PHONY: build up down logs test clean shell

build:
	docker build -t statuspulse:latest .

up:
	docker compose up -d --build

down:
	docker compose down

logs:
	docker compose logs -f

test:
	curl -f http://localhost:8000/health | python -m json.tool

clean:
	docker compose down -v --rmi all

shell:
	docker exec -it statuspulse-app bash