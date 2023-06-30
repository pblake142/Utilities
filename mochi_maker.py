# A barebones utility to generate Mochi cards based on text passed through the terminal

import json
import openai
import os
import re
import time

openai.api_key = os.getenv("OPENAI_API_KEY")

MOCHI_QUESTIONS_GENERATOR_SYSTEM_PROMPT = "You are a question generation program. When you are provided with a user message, write a list of all questions about the information conatined in the user message. No two questions should ask about the same information from the user message. Print the questions in a numbered format."
MOCHI_ANSWER_GENERATOR_SYSTEM_PROMPT = "You are an answer generation program. When you are provided with a user message, it will contain text before a list of numbered questions. The numbered questions will begin after the '-----' string. Write answers for each of the numbered questions using the text preceding it."

def openAIGPTCall(system_prompt,user_prompt,model="gpt-3.5-turbo-0615"):
  message_history = [{
    "role": "system",
    "content": system_prompt
  }, {
    "role": "user",
    "content": user_prompt
  }]

  start_time = time.time()
  response = openai.ChatCompletion.create(model=model,
                                          messages=message_history,
                                          temperature=0.8)
  elapsed_time = (time.time() - start_time) * 1000
  cost_factor = 0.06 if model == "gpt-4-0613" else 0.002
  cost = cost_factor * (response.usage["total_tokens"] / 1000)
  message = response.choices[0].message.content.strip()
  return message, cost, elapsed_time

def question_generator(text):
  system_prompt = MOCHI_QUESTIONS_GENERATOR_SYSTEM_PROMPT
  user_prompt = text

  print("Passing text to generate questions.")
  questions,question_cost,question_time = openAIGPTCall(system_prompt,user_prompt,model="gpt-4-0613")
  print("Questions generated.")
  return questions, question_cost, question_time

def answer_generator(text, questions):
  system_prompt = MOCHI_ANSWER_GENERATOR_SYSTEM_PROMPT
  user_prompt = text+'-----'+questions

  print(f"user_prompt: {user_prompt}")

  print("Passing text and questions to generate answers.")
  answers, answer_cost, answer_time = openAIGPTCall(system_prompt,user_prompt,model='gpt-3.5-turbo-0613')
  print("Answers generated.")
  return answers, answer_cost, answer_time

def content_generator(questions,answers):
  
  question_list = re.findall(r'(\d{1,2})\. (.*?)(?=\n\d{1,2}\.|$)', questions, re.DOTALL)
  answer_list = re.findall(r'(\d{1,2})\. (.*?)(?=\n\d{1,2}\.|$)', answers, re.DOTALL)

  # Creating a txt file that I can use to debug
  with open('questions.txt','w') as f:
    f.write(questions)

  qa_list = [{'content': f"{q[1]}\n---\n{a[1]}"} for q, a in zip(question_list, answer_list) if q[0] == a[0]]

  # Creating a txt file that I can use to debug
  with open('qa_list.txt','w') as f:
    f.write(str(qa_list))

  return qa_list

def add_content(text):
  global edn, total_cost, total_time
  
  questions, question_cost, question_time = question_generator(text)
  answers, answer_cost, answer_time = answer_generator(text,questions)
  qa_list = content_generator(questions,answers)

  for pair in qa_list:
    edn += "{:content \"" + pair['content'] + "\"}\n"

  total_cost += question_cost+answer_cost
  total_time += question_time+answer_time

# Set variables for whole praogram
total_cost = 0
total_time = 0

print("What do we call this deck?")
deck_name = input().strip()

edn = f'{{:version 2\n :decks [{{:name "{deck_name}" + \n:cards ['

while True:
    print("Provide the next text (or type 'Quit' to finish):")
    text = input().strip()

    if text.lower() == 'quit':
      break

    text = json.dumps(text)
    add_content(text)

edn += "]}]}"

filename = deck_name.replace(' ', '_') + '.edn'

with open(filename,'w') as f:
  f.write(edn)

print(f"Total cost: {total_cost}")
print(f"Total_time: {total_time}")
