FROM python:3.8 AS build

WORKDIR /app

RUN pip --no-cache-dir install poetry==1.0.0b4

RUN poetry config virtualenvs.in-project true

COPY pyproject.toml poetry.lock ./

RUN poetry install --no-dev

COPY main.py ./

# --- --- ---

FROM python:3.8-slim AS runtime

WORKDIR /app

ENV PATH="/app/.venv/bin:$PATH"

COPY --from=build /app/ ./

# https://stackoverflow.com/q/29663459/4494375
CMD [ "python", "-u", "main.py" ]
